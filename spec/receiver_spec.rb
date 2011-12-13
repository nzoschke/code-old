require "./spec/spec_helper"

describe Code::Receiver do
  it "starts a git HTTP backend" do
    @s = mock("unicorn http server")
    Unicorn::HttpServer.should_receive(:new).with(an_instance_of(GitHttp::App), {:listeners=>[]}).and_return(@s)
    @s.should_receive(:start).and_return(@s)
    @s.should_receive(:join).and_return(@s)

    Code::Receiver.start_server!
  end
end