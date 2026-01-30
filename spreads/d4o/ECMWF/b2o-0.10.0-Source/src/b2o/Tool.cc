#include "b2o/Tool.h"

#include <fcntl.h>  // ::open
#include <unistd.h> // ::close

#include <climits> // LONG_MAX

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

#include <eccodes.h>

#include <eckit/exception/Exceptions.h>
#include <eckit/filesystem/PathName.h>

#include <odc/api/odc.h>

#include "b2o_api.h"
#include "b2o/schema.h"

#include <sys/stat.h>

using namespace std;
using namespace eckit;

namespace {

  pair<string, string> split_at(const string& s, size_t pos, size_t gap = 0)
  {
    return make_pair(s.substr(0, pos), s.substr(pos == string::npos ? s.size() : pos + gap));
  }

  pair<string, string> split_on_first(const string& s, const string& d)
  {
    return split_at(s, s.find(d), d.size());
  }

  pair<string, string> split_on_last(const string& s, const string& d)
  {
    return split_at(s, s.find_last_of(d), d.size());
  }

  string column_name_of(const string& name)
  {
    string result;
    tie(result, ignore) = split_on_first(name, "@");
    return result;
  }

  string table_name_of(const string& name)
  {
    string result;
    tie(ignore, result) = split_on_first(name, "@");
    return result;
  }

  string prefix_of(const string& name)
  {
    string result;
    tie(result, ignore) = split_on_last(column_name_of(name), "_");
    return result;
  }

  int suffix_of(const string& name)
  {
    string result;
    tie(ignore, result) = split_on_last(column_name_of(name), "_");

    try {
      return stoi(result);
    }
    catch (invalid_argument e) {
      return 0;
    }
  }

  struct column_attrs_t {
    string name;
    int type;
    int size;
    vector<string> bitfield_names;
    vector<int> bitfield_sizes;
  };

  vector<column_attrs_t> merge_adjacent_string_columns(const vector<column_attrs_t>& columns) {

    // Merges adjacent string columns that form a long string (e.g. wigosid_[1-4]@hdr -> wigosid@hdr).

    vector<column_attrs_t> new_columns;
    new_columns.reserve(columns.size());

    if (!columns.empty()) {
      new_columns.push_back(columns[0]);
    }

    for (auto i = 1; i < columns.size(); ++i)  {

      const bool are_adjacent_string_columns = (
						columns[i-1].type == ODC_STRING
						&& columns[i-1].type == columns[i].type
						&& prefix_of(columns[i-1].name) == prefix_of(columns[i].name)
						&& suffix_of(columns[i-1].name) == suffix_of(columns[i].name)-1 );

      if (are_adjacent_string_columns) {
	new_columns.back().name = prefix_of(columns[i].name);
	new_columns.back().name += "@" + table_name_of(columns[i].name);
	new_columns.back().size = suffix_of(columns[i].name);
      } else {
	new_columns.push_back(columns[i]);
      }
    }

    return new_columns;
  }

  vector<column_attrs_t> get_frame_columns(const b2o_frame_t* f, int *mask, bool *is_masked, bool omit_masked) {

    char *env = (mask && is_masked) ? ::getenv("ODC_COL_FILTER") : NULL; // special: "*" enables all but keeps masking on
    bool allstar = false;
    size_t envlen = env ? strlen(env) : 0;
    string envcmp;
    if (envlen > 0) {
      if (envlen == 1 && *env == '*') {
	allstar = true;
	envlen = 0;
      }
      else {
	string tmp = env;
	envcmp = "," + tmp + ",";
      }
    }

    int count = 0;
    b2o_frame_column_count(f, &count);

    vector<column_attrs_t> columns;
    columns.reserve(count);

    if (is_masked) *is_masked = allstar;

    static bool display_once = true;
    if (display_once) {
      env = ::getenv("ODC_PROGRESS");
      if (env) {
	if (strcasecmp(env,"1") == 0 ||
	    strcasecmp(env,"on") == 0 ||
	    strcasecmp(env,"true") == 0 ||
	    strcasecmp(env,".true.") == 0) display_once = true;
	else
	  display_once = false;
      }
      else
	display_once = false;
    }

    bool first = true;
    int out_index = 0;
    
    for (int index = 0; index < count; ++index) {

      char name[128];
      int type, maskidx = index;
      const int size = 1;
      vector<string> bitfield_names;
      vector<int> bitfield_sizes;

      b2o_frame_column_name(f, index, name, sizeof(name));
      tie(type, bitfield_names, bitfield_sizes) = b2o::get_column_attrs(name);

      if (envlen > 0) {
	string tmp = name;
	string s = "," + tmp + ",";
	const char *p = strstr(envcmp.c_str(),s.c_str());
	if (!p) {
	  // trying to omit the "@table"
	  char *ss = strdup(s.c_str());
	  char *at = strchr(ss,'@');
	  if (at) {
	    *at++ = ','; *at = 0; // ",colname@table," --> ",colname,"
	    p = strstr(envcmp.c_str(),ss);
	  }
	  free(ss);
	  if (!p) {
	    // mask this column out
	    maskidx = -1;
	    if (is_masked) *is_masked = true;
	  }
	  else
	    ++out_index;
	  
	}
      }

      if (display_once) {
	/*
	  {"INTEGER", ODC_INTEGER}, {"YYYYMMDD", ODC_INTEGER}, {"HHMMSS", ODC_INTEGER},
	  {"PK1INT",  ODC_INTEGER}, {"PK9INT",   ODC_INTEGER}, {"@LINK",  ODC_INTEGER},
	  {"REAL",    ODC_REAL   }, {"FLOAT",    ODC_REAL   },
	  {"DOUBLE",  ODC_DOUBLE }, {"PK9REAL",  ODC_DOUBLE },
	  {"STRING",  ODC_STRING }
	*/
	if (first) {
	  fprintf(stderr,"\t---------------\n");
	  first = false;
	}
	fprintf(stderr,"\tODC-columns#%-3d : %40s %10s : %4d => %4d %s\n",
		index,name,
		(type == ODC_REAL) ? "REAL" :
		(type == ODC_DOUBLE) ? "DOUBLE" :
		(type == ODC_INTEGER) ? "INTEGER" :
		(type == ODC_STRING) ? "STRING" :
		(type == ODC_BITFIELD) ? "BITFIELD" : "unknown",
		(maskidx >= 0) ? maskidx+1 : maskidx,
		(maskidx >= 0 && out_index > 0) ? out_index : (maskidx >= 0 && out_index == 0) ? maskidx+1 : -1,
		(maskidx >= 0) ? "=> available" : "(omitted)");
      }
      
      if (maskidx == index) {
	columns.push_back({name, (mask && type == ODC_BITFIELD) ? ODC_INTEGER : type, size, bitfield_names, bitfield_sizes});
      }
      else if (!omit_masked) {
	snprintf(name,sizeof(name),"_%d",index+1);
	columns.push_back({name, (type == ODC_BITFIELD) ? ODC_INTEGER : type, size, bitfield_names, bitfield_sizes});
      }
      if (mask) mask[index] = maskidx+1; // Fortran index from 1
    }

    //display_once = false;
    return (is_masked && *is_masked) ? columns : merge_adjacent_string_columns(columns);
  }

  void set_encoder_columns(odc_encoder_t* e, const vector<column_attrs_t>& columns) {

    ASSERT(e);

    int c_index = 0;

    for (const auto& c: columns) {
      odc_encoder_add_column(e, c.name.c_str(), c.type);
      odc_encoder_column_set_data_size(e, c_index, c.size * sizeof(double));
      if (c.type == ODC_BITFIELD) {
	for (auto i = 0; i < c.bitfield_names.size(); ++i) {
	  odc_encoder_column_add_bitfield(e, c_index, c.bitfield_names[i].c_str(), c.bitfield_sizes[i]);
	}
      }
      ++c_index;
    }
  }

  long GetFileSize(const string &filename)
  {
    struct stat stat_buf;
    int rc = stat(filename.c_str(), &stat_buf);
    return rc == 0 ? stat_buf.st_size : -1;
  }
  
  long RemoveIfEmpty(const string &filename)
  {
    long rc = GetFileSize(filename);
    if (rc == 0) {
      cerr << "Warning: Removing empty ODC-dbfile " << filename << endl;
      ::unlink(filename.c_str());
    }
    return rc;
  }
  
  void encode_frame_to_file_descriptor(odc_encoder_t** e, const b2o_frame_t* fs, int fd, bool new_columns, int *mask, bool *is_masked, bool omit_masked, const string &ofile) {

    ASSERT(fs);

    long width, height, size;
    const void* data = nullptr;
    const bool column_major = false;

    if (new_columns || !*e) {
      if (*e) odc_free_encoder(*e);
      odc_new_encoder(e);
      const auto columns = get_frame_columns(fs,mask,is_masked,omit_masked);
      set_encoder_columns(*e, columns);
    }
      
    b2o_frame_shape(fs, &width, &height);
    b2o_frame_data(fs, &data, sizeof(double), &size);

    //if (width > 0) { // no columns : either not selected or no rows ever to be written
      odc_encoder_set_row_count(*e, height);
      odc_encoder_set_data_array(*e, data, width * sizeof(double), height, column_major);
      fprintf(stderr,"encode_frame_to_file_descriptor(): e=%p *e=%p data=%p width=%ld widthx%ld=%ld height=%ld ODCFILE=%s\n",
	      e,*e,data,width,sizeof(double),width*sizeof(double),height,ofile.c_str());
      odc_encode_to_file_descriptor(*e, fd, nullptr);
    //}
  }

} // namespace (anonymous)

extern "C" {

  void b2o_rethrow_current_exception(void* context, int error_code) { throw std::current_exception(); }

} // extern "C"

namespace b2o {

  void Tool::usage(ostream& o)
  {
    o << " usage: b2o [options] bufr-input [ -o odb-output ]" << endl;
    o << endl;
    o << " options:" << endl;
    o << "   -o FILE                    specify the ODB output file" << endl;
    o << "   --code-mappings-file FILE  path to ODB code mappings file" << endl;
    o << "   --schema-file FILE         path to ODB schema file (e.g. cma.ddl)" << endl;
    o << "   --all-sky                  extract all-sky data" << endl;
    o << "   --macc                     extract ozone for MACC/CAMS project" << endl;
    o << "   --macc-206                 extract ozone (and standard ozone) for MACC/CAMS project" << endl;
    o << "   --verbose                  turn on verbose output" << endl;
    o << endl;
  }

  Tool::Tool(int argc, char* argv[])
    : eckit::Tool(argc, argv), odc::tool::CommandLineParser(argc, argv)
  {
    b2o_init(argc, argv);
    registerOptionWithArgument("-o");
  }

  Tool::~Tool()
  {}

  void Tool::run()
  {
    vector<string> arguments = parameters();    

    if (arguments.size() == 1) {
      cerr << endl;
      cerr << " b2o - convert BUFR data into ODB format" << endl;
      cerr << endl;
      usage(cerr);
      return;
    }
    else if (arguments.size() != 2) {
      throw eckit::UserError("Invalid number of arguments");
    }

    const string inputFile = arguments[1];
    FILE* input = ::fopen(inputFile.c_str(), "r");
    if (input == nullptr) throw CantOpenFile(inputFile);

    string outputFile = optionArgument<string>("-o", "");
    const string outputFilePrefix = outputFile;
    int fileinc = 0;
    outputFile = outputFilePrefix + "." + to_string(fileinc++);
    int output = ::open(outputFile.c_str(), O_CREAT|O_TRUNC|O_WRONLY, 0666);
    if (output == -1) throw CantOpenFile(outputFile);
    cerr << "Processing ODCFILE=" << outputFile << endl;

    odc_integer_behaviour(ODC_INTEGERS_AS_DOUBLES);
    odc_set_failure_handler(b2o_rethrow_current_exception, nullptr);

    b2o_context_t* x = nullptr;
    b2o_converter_t* c = nullptr;
    b2o_frame_t* f = nullptr;
    b2o_frame_t* fs = nullptr;

    b2o_new_context(&x, nullptr);
    b2o_new_converter(&c);
    b2o_new_frame(&f);
    b2o_new_frame(&fs);

    b2o_context_set_message_source(x, inputFile.c_str());

    int error;
    bool new_columns;
    codes_handle* h = nullptr;
    odc_encoder_t* e = nullptr;
    
    int *mask = nullptr;
    int nmask = 0;
    bool is_masked = false;
    //bool first_time = true;

    char *env;

    bool progress = false;
    env = ::getenv("ODC_PROGRESS");
    if (env) {
      if (strcasecmp(env,"1") == 0 ||
	  strcasecmp(env,"on") == 0 ||
	  strcasecmp(env,"true") == 0 ||
	  strcasecmp(env,".true.") == 0) progress = true;
    }
    
    env = ::getenv("ODC_ROW_CHUNK");
    //const long row_chunk_default = 300000; // originally 10,000
    const long row_chunk_default = 1000000; // originally 10,000
    long row_chunk = env ? atol(env) : row_chunk_default;
    if (row_chunk < 1) row_chunk = row_chunk_default;

    long total_blks = 0;
    long long int total_in = 0;
    long long int total_out = 0;
    long width, height; // fs
    long wh,ht; // f

    env = ::getenv("ODC_BUFR_COUNT");
    long int bufr_count = env ? atol(env) : -1;
    if (bufr_count < 0) bufr_count = -1;
    env = ::getenv("ODC_BUFR_FIRST_MSG");
    long int first_msg = env ? atol(env) : 1;
    if (first_msg < 1) first_msg = 1;
    env = ::getenv("ODC_BUFR_LAST_MSG");
    long int very_big = LONG_MAX-first_msg;
    long int last_msg = env ? atol(env) : very_big;
    if (last_msg < 1 || last_msg > very_big) last_msg = very_big;
    if (bufr_count > 0 && last_msg > bufr_count) last_msg = bufr_count;
    bool is_max = (last_msg >= very_big) ? true : false;
    long int msgid = 0;
    
    char fmt[] = "BUFR-msg#%7ld [%ld:%ld] -- <IN> %10lld x %ld : <OUT> %10lld x %ld [CACHED: %7ld x %ld] : OUT # of BLKS: %6ld\t[ODCFILE=%s]\n";
    
    while ((h = codes_bufr_handle_new_from_file(nullptr, input, &error)) != nullptr || error != CODES_SUCCESS) {
      if (++msgid >= first_msg) {
	const int status = b2o_convert_message_handle(x, c, h, f, &new_columns);
      
	if (status == B2O_SUCCESS) {
	  long htsaved = 0;
	  b2o_frame_shape(fs, &width, &height);

	  const bool encode_frame = (new_columns && height > 0) || (height >= row_chunk);

	  //if (encode_frame) new_columns = true; // Important ? YES, VERY IMPORTANT !!
	  
	  if (mask && new_columns) {
	    //fprintf(stderr,"nmask = %d : deleting mask = %p\n",nmask,mask);
	    delete [] mask;
	    mask = nullptr;
	    nmask = 0;
	  }
		
	  if (!mask) {
	    b2o_frame_column_count(f,&nmask);
	    mask = new int [nmask];
	    //fprintf(stderr,"nmask = %d : new mask = %p\n",nmask,mask);
	    (void) get_frame_columns(f,mask,&is_masked,true);
	  }

	  if (encode_frame) {
	    long tmp;
	    b2o_frame_shape(fs, &tmp, &htsaved);
	    encode_frame_to_file_descriptor(&e, fs, output, new_columns, NULL, NULL, true, outputFile);
	    if (htsaved > 0) ++total_blks;
	    b2o_frame_clear(fs); // clear now fixed !!
	    
	    if (new_columns) {
	      // We need to close this output ODCFILE and open a new one
	      odc_free_encoder(e);
	      e = nullptr;
	      ::close(output);
	      long fsize = RemoveIfEmpty(outputFile);
	      if (fsize > 0) cout << "ODCFILE=" << outputFile << " " << to_string(fsize) << " bytes" << endl;
	      cerr << "ODCFILE=" << outputFile << " " << to_string(fsize) << " bytes" << endl;
	      outputFile = outputFilePrefix + "." + to_string(fileinc++);
	      output = ::open(outputFile.c_str(), O_CREAT|O_TRUNC|O_WRONLY, 0666);
	      if (output == -1) throw CantOpenFile(outputFile);
	      cerr << "Processing ODCFILE=" << outputFile << endl;
	    }
	  }
	
	  if (is_masked) {
	    b2o_frame_masked_append(fs, f, mask, nmask);
	  }
	  else {
	    b2o_frame_append(fs, f);
	  }

	  {
	    b2o_frame_shape(f, &wh, &ht);
	    total_in += ht;
	    b2o_frame_shape(fs, &width, &height);
	    if (encode_frame) total_out += htsaved;
	    if (encode_frame && progress) fprintf(stderr,fmt,msgid,first_msg,is_max?-1:last_msg,total_in,wh,total_out,width,height,width,total_blks,outputFile.c_str());
	  }

	}
      }

      codes_handle_delete(h);
      
      if (msgid >= last_msg) break;
    }

    encode_frame_to_file_descriptor(&e, fs, output, new_columns, is_masked ? mask : NULL, is_masked ? &is_masked : NULL, true, outputFile);

    {
      b2o_frame_shape(fs, &width, &height);
      total_out += height;
      if (height > 0) ++total_blks;
      if (progress) {
	char *p = strchr(fmt,'\r');
	if (p) *p = '\n';
	fprintf(stderr,fmt,msgid,first_msg,is_max?-1:last_msg,total_in,wh,total_out,width,height,width,total_blks,outputFile.c_str());
      }
    }
    
    if (mask) {
      delete [] mask;
      mask = nullptr;
      nmask = 0;
      is_masked = false;
    }

    b2o_delete_frame(fs);
    b2o_delete_frame(f);
    b2o_delete_converter(c);
    b2o_delete_context(x);
    odc_free_encoder(e);

    ::fclose(input);
    ::close(output);

    long fsize = RemoveIfEmpty(outputFile);
    if (fsize > 0) cout << "ODCFILE=" << outputFile << " " << to_string(fsize) << " bytes" << endl;
    cerr << "ODCFILE=" << outputFile << " " << to_string(fsize) << " bytes" << endl;
  }

} // namespace b2o
