
module PolySSH
  class CommandBuilder
    include VisitorBase 

    def initialize 
      @commands = []
      @last_command = ""
      @baseport = 18000 + rand(2000)
    end

    # Visit node list
    def visit_polyssh_nodelist node_list
        if node_list.count > 0 then
          node_list.first.accept(self)
        end
    end

    # Visit each node entry
    def visit_polyssh_nodeentry node_entry
      cmd=""
      if @commands.empty? and node_entry.next.nil? then
        cmd = ("ssh " +
               "-o ForwardAgent=yes " +
               "-o UserKnownHostsFile=/dev/null " +
               "-o StrictHostKeyChecking=no " +
               "-p #{node_entry.port} " +
               "-l #{node_entry.user} " +
               "#{node_entry.host} " 
              )
        @commands << [@baseport, cmd]
      elsif node_entry.next.nil? then
        cmd = ("ssh " +
               "-o ForwardAgent=yes " +
               "-o UserKnownHostsFile=/dev/null " +
               "-o StrictHostKeyChecking=no " +
               "-p #{@baseport} " +
               "-l #{node_entry.user} " +
               "localhost " 
              )
        @commands << [@baseport, cmd]
      else
        get_port
        next_entry = node_entry.next 
        cmd = (
          "ssh " +
          "-o ForwardAgent=yes " +
          "-o UserKnownHostsFile=/dev/null " +
          "-o StrictHostKeyChecking=no " +
          "-N " +
          "-L#{@baseport}:#{next_entry.host}:#{next_entry.port} " +
          "-l #{node_entry.user} #{node_entry.host} "
        )
        @commands << [@baseport, cmd]
        next_entry.accept(self)
      end
    end

    # Detect next available port
    def get_port
      @baseport += 1
      while !port_open?(@baseport) do  
        @baseport += 1
      end
    end

    # Test if given port is locally used
    def port_open?(port)
        !system("lsof -i:#{port}", out: '/dev/null')
    end
  end
end

