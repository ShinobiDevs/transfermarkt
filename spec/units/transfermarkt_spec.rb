require 'spec_helper'

describe Transfermarkt do
  it "should respond to base_uri" do
    expect(Transfermarkt.respond_to?(:base_uri)).to be_truthy
  end

  it "should have a user agent by default" do
    expect(Transfermarkt::USER_AGENT).to eq("Firefox")
  end
end
