require "./spec/spec_helper"

describe "Code::Monitor" do
  before do
    @mon = Code::Monitor.new
  end

  it "has a target number of processes" do
    @mon.num_processes.should == 5
  end

  it "has a collection of running processes" do
    @mon.processes.should == []
  end

  it "starts a new process with an environment" do
    pid = @mon.start("bin/backend", {PORT: 5100})
    @mon.processes.should == [pid]
  end

  it "generates an environment" do
    @mon.generate_env.should == {PORT: 9999}
  end

  it "polls running processes" do
    @mon.poll("bin/backend") == []
  end

  it "starts backends to satisfy num_backends" do
    @mon.should_receive(:poll).with("bin/backend").and_return([])
    @mon.should_receive(:start).with("bin/backend", any).times(5)

    @mon.start_all
    @mon.process.length.should == 5
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