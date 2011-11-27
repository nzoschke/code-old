module Bash
  class BashError < RuntimeError; end;

  def bash(opts={})
    opts = {env: {}, err: false, src: ""}.merge(opts)

    r0, w0 = IO.pipe
    r1, w1 = IO.pipe

    w0.write opts[:src]
    w0.close

    pid = Process.spawn(opts[:env], "bash -s", :in => r0, :out => w1)
    Process.wait(pid)
    w1.close
    r = [r1.read, $?.exitstatus]

    raise BashError if r[1] != 0 && opts[:err]
    r
  end
end

require "minitest/autorun"
describe Bash do
  include Bash

  it "runs shell source and returns output and exit status" do
    bash(src: "printf 'hello world'").must_equal ["hello world", 0]
  end

  it "raises an exception on non-zero exit with err: true" do
    proc { bash(src: "false", err: true) }.must_raise BashError
  end
end
