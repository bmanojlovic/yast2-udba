# encoding: utf-8

module Yast
  class UdbaClient < Client
    def main

      # testedfiles: Udba.ycp

      Yast.include self, "testsuite.rb"
      TESTSUITE_INIT([], nil)

      Yast.import "Udba"

      DUMP("Udba::Modified")
      TEST(lambda { Udba.Modified }, [], nil)

      nil
    end
  end
end

Yast::UdbaClient.new.main
