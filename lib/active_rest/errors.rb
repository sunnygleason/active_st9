module ActiveRest
  module Errors
    class AttributeCollision < RuntimeError
      def initialize(attribute_name)
        @attribute_name = attribute_name
      end

      def to_s
        "You tried to name an attribute (#{@attribute_name}) that shares a name with an existing method. You probably don't want to do this."
      end
    end

    class InvalidKind < RuntimeError
      def initialize(kind_name)
        @kind_name = kind_name
      end

      def to_s
        "Kind #{@kind_name} is not a known or valid class. Maybe your class definitions do not match your database?"
      end
    end

    class InvalidValue < RuntimeError
      def to_s
        "Invalid value assignment"
      end
    end

    class PersistenceError < RuntimeError
      def initialize(response_body)
        @response_body = response_body
      end

      def to_s
        "Call to datastore failed, server returned the following message:\n\t#{@response_body}"
      end
    end

    class InvalidIndex < RuntimeError; end

    class InvalidSchema < RuntimeError; end

    class InvalidCounter < RuntimeError; end

    class NotFoundError < RuntimeError; end

    class QuarantineError < RuntimeError
      def initialize(response)
        @response = response
      end

      def to_s
        "Server returned the following message:\n\t#{@response.try(:body)} (#{@response.try(:status)})"
      end
    end

    class ObsoleteVersionError < PersistenceError; end

    class UnexpectedRemoteServiceError < PersistenceError; end

    class DuplicateKeyError < PersistenceError; end

    class InvalidClientRequestError < PersistenceError; end

    class InvalidFindableIDError < StandardError; end

    class ValidationError < RuntimeError
      def initialize(errors)
        @errors = errors
      end

      def to_s
        "Object could not be saved since #{@errors.inspect}"
      end
    end

    class InvalidAssociation < RuntimeError
      def initialize(obj_class, expected_class)
        @obj_class, @expected_class = obj_class, expected_class
      end

      def to_s
        "Tried to associate a #{@obj_class} when we expected #{@expected_class}"
      end
    end

    class InvalidArgument < RuntimeError
      def initialize(arg)
        @arg = arg
      end

      def to_s
        "Invalid argument: #{@arg}"
      end
    end

    class NotStaticAttribute < RuntimeError
      def initialize(attribute)
        @attribute = attribute
      end

      def to_s
        "Tried to use a nonexistant or dynamic attribute where a static one was required: #{@attribute}"
      end
    end

    class NoIndex < RuntimeError
      def initialize(index)
        @index = index
      end

      def to_s
        "No index defined: #{@index}"
      end
    end

    class NonUniqueIndex < RuntimeError
      def initialize(index)
        @index = index
      end

      def to_s
        "Index is not unique: #{@index}"
      end
    end

    class NoCounter < RuntimeError
      def initialize(counter)
        @counter = counter
      end

      def to_s
        "No counter defined: #{@counter}"
      end
    end

    class CascadeError < RuntimeError
      def to_s
        "You triggered a cascading operation. Set `allow_cascades` in the configuration to enable."
      end
    end
  end
end
