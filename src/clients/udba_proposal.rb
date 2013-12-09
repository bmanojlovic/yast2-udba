# encoding: utf-8

# File:	clients/udba_proposal.ycp
# Package:	Universal Driver Build Assistant
# Summary:	Proposal function dispatcher.
# Authors:	Boris Manojlovic <boris@steki.net>
#
# $Id: udba_proposal.ycp $
#
# Proposal function dispatcher for udba configuration.
# See source/installation/proposal/proposal-API.txt
module Yast
  class UdbaProposalClient < Client
    def main

      textdomain "udba"

      Yast.import "Udba"
      Yast.import "Progress"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Udba proposal started")

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # create a textual proposal
      if @func == "MakeProposal"
        @proposal = ""
        @warning = nil
        @warning_level = nil
        @force_reset = Ops.get_boolean(@param, "force_reset", false)

        if @force_reset || !Udba.ProposalValid
          Udba.SetProposalValid(true)
          @progress_orig = Progress.set(false)
          Udba.Read
          Progress.set(@progress_orig)
        end
        @sum = Udba.Summary
        @proposal = Ops.get_string(@sum, 0, "")

        @ret = {
          "preformatted_proposal" => @proposal,
          "warning_level"         => @warning_level,
          "warning"               => @warning
        }
      # run the module
      elsif @func == "AskUser"
        @stored = Udba.Export
        @seq = Convert.to_symbol(WFM.CallFunction("udba", [path(".propose")]))
        Udba.Import(@stored) if @seq != :next
        Builtins.y2debug("stored=%1", @stored)
        Builtins.y2debug("seq=%1", @seq)
        @ret = { "workflow_sequence" => @seq }
      # create titles
      elsif @func == "Description"
        @ret = {
          # Rich text title for Udba in proposals
          "rich_text_title" => _("Udba"),
          # Menu title for Udba in proposals
          "menu_title"      => _("&Udba"),
          "id"              => "udba"
        }
      # write the proposal
      elsif @func == "Write"
        Udba.Write
      else
        Builtins.y2error("unknown function: %1", @func)
      end

      # Finish
      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("Udba proposal finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::UdbaProposalClient.new.main
