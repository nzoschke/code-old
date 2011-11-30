require "./spec/spec_helper"

describe "Code::Monitor" do
  before do
    @mon = Code::Monitor.new
  end

  after do
    @mon.kill_all
  end

  it "has a target number of processes" do
    @mon.num_processes.should == 5
  end

  it "has a collection of running processes" do
    @mon.processes.should == []
  end

  it "starts a new process with an environment" do
    pid = @mon.start("bin/monitor", {"PORT" => "5100"})
    @mon.processes.should == [pid]
  end

  it "generates an environment" do
    @mon.generate_env.keys.should == ["PORT"]
  end

  it "polls running processes" do
    @mon.poll("bin/monitor") == []
  end

  it "starts monitors to satisfy num_monitors" do
    @mon.start_all("bin/monitor")
    @mon.processes.length.should == 5
  end

  it "garbage collects stuff" do
    @mon.gc
  end

  context "Code::HerokuMonitor" do
    it "starts a new process with a Heroku API call" do
    end

    it "polls running processes with a Heroku API call" do
    end
  end
end