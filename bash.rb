module Bash
  class BashError < RuntimeError; end;

  def bash(opts={})
    opts = {env: {}, err: false, src: "", timeout: 5}.merge(opts)

    p0, p1, p2 = IO.pipe, IO.pipe, IO.pipe

    p0[1].write opts[:src]
    p0[1].close

    pid = Process.spawn(opts[:env], "bash -s", in: p0[0], out: p1[1], err: p2[1])
    Process.wait(pid)
    p1[1].close
    p2[1].close
    r = [p1[0].read, p2[0].read]

    raise BashError if r[1] != 0 && opts[:err]
    r
  end
end

require "minitest/autorun"
describe Bash do
  include Bash

  it "runs source in bash" do
    bash(src: "printf $SHELL").must_equal ["/bin/bash", ""]
  end

  it "runs source and returns stdout and stderr" do
    bash(src: "set -x; printf hi").must_equal ["hi", "+ printf hi\n"]
  end

  it "preserves $?" do
    bash(src: "exit 2")
    $?.exitstatus.must_equal 2
  end

  it "raises an exception on non-zero exit with err: true" do
    proc { bash(src: "false", err: true) }.must_raise BashError
  end

  it "runs multiline shell scripts" do
    o, e = bash src: <<-EOF
      echo thing1
      echo thing2
    EOF
    o.must_equal "thing1\nthing2\n"
  end

  it "takes an env hash" do
    bash(src: "printf $FOO", env: {"FOO" => "bar"}).must_equal ["bar", ""]
  end
end
