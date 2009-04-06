class Jeweler
  class Generator
    module MicronautMixin
      
      def default_task
        'examples'
      end

      def feature_support_require
        'micronaut/expectations'
      end

      def feature_support_extend
        'Micronaut::Matchers'
      end

      def test_dir
        'examples'
      end

      def test_or_spec
        'example'
      end
    end
  end
end
