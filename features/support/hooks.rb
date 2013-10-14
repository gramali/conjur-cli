require 'ostruct'

class MockAPI
  attr_reader :things
  
  def initialize
    @things = {}
  end
  
  def thing(kind, id)
    (@things[kind.to_sym] || []).find{|r| r.id == id}  
  end
  
  def create_resource(id, options = {})
    resource(id).tap do |resource|
      resource.send(:"exists?=", true)
      populate_options resource, options
    end
  end
  
  def create_role(id, options = {})
    role(id).tap do |role|
      role.send(:"exists?=", true)
      populate_options role, options
    end
  end
  
  def role(id)
    raise "Role id must be a string" unless id.is_a?(String)
    thing(:role, id) || create_thing(:role, id, exists?: false)
  end
  
  def resource(id)
    raise "Resource id must be a string" unless id.is_a?(String)
    thing(:resource, id) || create_thing(:resource, id, exists?: false)
  end
  
  protected
  
  def create_thing(kind, id, options)
    thing = OpenStruct.new(kind: kind, id: id, exists?: true)
    
    if kind == :resource
      class << thing
        def permit(privilege, role, options = {})
          (self.permissions ||= []) << OpenStruct.new(privilege: privilege, role: role.id, grant_option: !!options[:grant_option])
        end
      end
    end
    
    if kind == :role
      class << thing
        def can(privilege, resource, options = {})
          resource.permit privilege, self, options
        end
      end
    end
    
    populate_options(thing, options)
    
    store_thing kind, thing
    
    thing
  end
  
  def populate_options(thing, options)
    options.each do |k,v|
      thing.send("#{k}=", v)
    end
  end
  
  def store_thing(kind, thing)
    (things[kind] ||= []) << thing
  end
end

Before("@dsl") do
  puts "Using MockAPI"
  puts "Using account 'cucumber'"
  
  require 'conjur/api'
  require 'conjur/dsl/runner'

  Conjur::Core::API.stub(:conjur_account).and_return 'cucumber'
  @mock_api ||= MockAPI.new
  Conjur::DSL::Runner.any_instance.stub(:api).and_return @mock_api
end