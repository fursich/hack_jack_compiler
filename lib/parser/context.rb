require_relative 'nodes/node'

module JackCompiler
  module Parser
    class Context
      attr_reader :parents

      def initialize
        @parents = []
      end

      def execute_with(node, &block)
        link! node if current_parent

        parents.push node

        result = yield

        node = parents.pop

      rescue
        node = parents.pop

        # cancellation required if it's aborted via exception
        # XXX this class should not concern about the need for connecting nodes
        # as it involves the knowlegde on when/where exception is raised.
        # instead, let Prcessor handle #link / #unlink as its client.
        unlink! if current_parent&.children

        raise
      ensure

        result
      end

      def current_parent
        parents.last
      end

      def link!(node)
        current_parent.push node
      end

      def unlink!
        current_parent.pop
      end

      def root_node
        parents.first
      end
    end
  end
end
