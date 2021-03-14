require "./spec_helper"

describe Datcord do
  with_server do
    it "should ping back" do
      result = curl("GET", "/v1/ping")
      result.body.includes?("ok").should eq(true)
    end
  end
end
