module ErrorsModule
  class CustomError < StandardError
    attr_reader :status, :error, :message

    def initialize( _error=nil, _status=nil, _message=nil )
      @error = _error || 422
      @status = _status || :unprocessable_entity
      @message = _message || 'Something went wrong'
    end

  end

  class InvalidParamsError < CustomError
    def initialize( _message )
      super( nil, nil, _message )
    end
  end

  class UnAuthorizedAccessError < CustomError
    def initialize
      super( 401, :unauthorized_access, "Unauthorized Access")
    end
  end

end
