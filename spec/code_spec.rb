require "./lib/code"

describe "Ruby" do
  it "patches Hash with reverse_merge!" do
    opts = {}
    opts.reverse_merge!(timeout: 10)
    opts.should == { timeout: 10 }

    opts = { timeout: 20 }
    opts.reverse_merge!(timeout: 10)
    opts.should == { timeout: 20 }
  end
end
