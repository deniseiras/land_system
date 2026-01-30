'''
Created on May 7, 2014

@author: pascale
'''

import unittest
import rttov
import h5py
import rmodel
import logging
import glob
from test import rttovgui_unittest_class
import sys


class Test(rttovgui_unittest_class.RttovGuiUnitTest):

    def setUp(self):
        level_logging = logging.DEBUG
        self.p = rmodel.project.Project()

        logging.basicConfig(filename=(self.p.config.ENV['GUI_WRK_DIR'] +
                                      "/rttovgui_unittest_test_full.log"),
                            format=("[%(asctime)s] %(levelname)s [%(module)s:"
                                    "%(funcName)s:%(lineno)d] %(message)s"),
                            level=level_logging,
                            datefmt="%Y:%m:%d %H:%M:%S",
                            filemode="w")


#    def tearDown(self):
#        pass

    def test_full(self):

        list_std = []
        list_profiles = []
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov7pred54L/*.H5"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov8pred54L/*.H5"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov9pred54L/*.H5"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov7pred101L/*.H5"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov8pred101L/*.H5"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov9pred101L/*.H5"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov7pred54L/*.dat"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov8pred54L/*.dat"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov9pred54L/*.dat"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov7pred101L/*.dat"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov8pred101L/*.dat"):
            list_std.append(coefFile)
        for coefFile in glob.glob(self.p.config.ENV["RTTOV_GUI_COEFF_DIR"] +
                                  "/rttov9pred101L/*.dat"):
            list_std.append(coefFile)
        for profileFile in glob.glob(self.p.config.ENV[
                "RTTOV_GUI_PROFILE_DIR"] + "/*.H5"):
            list_profiles.append(profileFile)
        print(list_profiles)
        for coefFile in list_std:

            self.p.myCoeffs.fileName["standard"] = coefFile
            err = self.p.loadCoefficients()
            self.assertEqual(err, 0)
            print(">>>>>>>>>>>>>>>>>>>>>coefFile;", coefFile, " loaded")
            for prof in list_profiles:
                print(">>>>>>>>>>>>>>>>>>>open profile ", prof)
                nb = rttov.profile.getNumberOfProfiles(prof)
                print("nb profiles", nb, "testing the first")
                for n in range(1, 2):
                    print(">>>>>>>>>>>>>>>profile ", prof, "number ", n)
                    self.p.openProfile(prof, n)

                    self.p.ctrlCoherence()
                    self.check_option(self.p)
                    err = self.p.runDirect()
                    self.assertEqual(err, 0)
                    err = self.p.runK()
                    self.assertEqual(err, 0)
                    self.check_option(self.p)
                    print(">>>>>>>>>>>>>>>>>>>>>>OK for ", coefFile, prof, n)

        print(">>>>>>>>>>>>>>>>> end test remove O3")


if __name__ == "__main__":
    unittest.main()
