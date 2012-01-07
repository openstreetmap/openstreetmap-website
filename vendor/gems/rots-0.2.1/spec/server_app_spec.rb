require File.join(File.dirname(__FILE__), 'spec_helper')

# This is just a comment test

describe Rots::ServerApp do

  describe "when the request is not an OpenID request" do

    it "should return a helpful message saying that is an OpenID endpoint" do
      request  = Rack::MockRequest.new(Rots::ServerApp.new({'sreg' => {}}, 
        {:storage => File.join(*%w(. tmp rots)) }))
      response = request.get("/")
      response.should be_ok
      response.body.should == "<html><body><h1>ROTS => This is an OpenID endpoint</h1></body></html>"
    end

  end

  describe "when the request is an OpenID request" do
    
    before(:each) do
      @request = Rack::MockRequest.new(Rots::ServerApp.new({
        'identity' => 'john.doe',
        'sreg' => {
          'email' => "john@doe.com",
          'nickname' => 'johndoe',
          'fullname' => "John Doe",
          'dob' => "1985-09-21",
          'gender' => "M"
        }},
        {:storage => File.join(*%w(. tmp rots))}
      ))
    end
    

    describe "and it is a check_id request" do

      describe "and is immediate" do

        it "should return an openid.mode equal to setup_needed" do
          response = checkid_immediate(@request)
          params = openid_params(response)
          params['openid.mode'].should == 'setup_needed'
        end

      end

      describe "and is not immediate" do

        describe "with a success flag" do

          it "should return an openid.mode equal to id_res" do
            response = checkid_setup(@request, 'openid.success' => 'true')
            params = openid_params(response)
            params['openid.mode'].should == 'id_res'
          end

        end

        describe "without a success flag" do

          it "should return an openid.mode equal to cancel" do
            response = checkid_setup(@request)
            params = openid_params(response)
            params['openid.mode'].should == 'cancel'
          end

        end
        
        describe "using SREG extension with a success flag" do
          
          it "should return an openid.mode equal to id_res" do
            response = checkid_setup(@request, 'openid.success' => 'true')
            params = openid_params(response)
            params['openid.mode'].should == 'id_res'
          end
          
          it "should return all the sreg fields" do
            response = checkid_setup(@request, {
              'openid.success' => true,
              'openid.ns.sreg' => OpenID::SReg::NS_URI,
              'openid.sreg.required' => 'email,nickname,fullname',
              'openid.sreg.optional' => 'dob,gender'
            })
            params = openid_params(response)
            params['openid.sreg.email'].should == "john@doe.com"
            params['openid.sreg.nickname'].should == 'johndoe'
            params['openid.sreg.fullname'].should == "John Doe"
            params['openid.sreg.dob'].should == "1985-09-21"
            params['openid.sreg.gender'].should == "M"
          end
          
        end
      
      end
    end
  end

end