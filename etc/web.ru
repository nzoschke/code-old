require "./lib/code"

map("/")        { run Code::Web::Director }
map("/pushes")  { run Code::Web::PushAPI  }