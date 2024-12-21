module Api
  module Users
    module DetailsTestHelper
      private

      def check_xml_details(user, include_private, include_email)
        assert_select "user[id='#{user.id}']", :count => 1 do
          assert_select "description", :count => 1, :text => user.description

          assert_select "contributor-terms", :count => 1 do
            if user.terms_agreed.present?
              assert_select "[agreed='true']", :count => 1
            else
              assert_select "[agreed='false']", :count => 1
            end

            if include_private
              assert_select "[pd='false']", :count => 1
            else
              assert_select "[pd]", :count => 0
            end
          end

          assert_select "img", :count => 0

          assert_select "roles", :count => 1 do
            assert_select "role", :count => 0
          end

          assert_select "changesets", :count => 1 do
            assert_select "[count='0']", :count => 1
          end

          assert_select "traces", :count => 1 do
            assert_select "[count='0']", :count => 1
          end

          assert_select "blocks", :count => 1 do
            assert_select "received", :count => 1 do
              assert_select "[count='0'][active='0']", :count => 1
            end

            assert_select "issued", :count => 0
          end

          if include_private && user.home_lat.present? && user.home_lon.present?
            assert_select "home", :count => 1 do
              assert_select "[lat='12.1'][lon='23.4'][zoom='3']", :count => 1
            end
          else
            assert_select "home", :count => 0
          end

          if include_private
            assert_select "languages", :count => 1 do
              assert_select "lang", :count => user.languages.count

              user.languages.each do |language|
                assert_select "lang", :count => 1, :text => language
              end
            end

            assert_select "messages", :count => 1 do
              assert_select "received", :count => 1 do
                assert_select "[count='#{user.messages.count}'][unread='0']", :count => 1
              end

              assert_select "sent", :count => 1 do
                assert_select "[count='#{user.sent_messages.count}']", :count => 1
              end
            end
          else
            assert_select "languages", :count => 0
            assert_select "messages", :count => 0
          end

          if include_email
            assert_select "email", :count => 1, :text => user.email
          else
            assert_select "email", :count => 0
          end
        end
      end

      def check_json_details(js, user, include_private, include_email)
        assert_equal user.id, js["user"]["id"]
        assert_equal user.description, js["user"]["description"]
        assert_operator js["user"]["contributor_terms"], :[], "agreed"

        if include_private
          assert_not js["user"]["contributor_terms"]["pd"]
        else
          assert_nil js["user"]["contributor_terms"]["pd"]
        end

        assert_nil js["user"]["img"]
        assert_empty js["user"]["roles"]
        assert_equal 0, js["user"]["changesets"]["count"]
        assert_equal 0, js["user"]["traces"]["count"]
        assert_equal 0, js["user"]["blocks"]["received"]["count"]
        assert_equal 0, js["user"]["blocks"]["received"]["active"]
        assert_nil js["user"]["blocks"]["issued"]

        if include_private && user.home_lat.present? && user.home_lon.present?
          assert_in_delta 12.1, js["user"]["home"]["lat"]
          assert_in_delta 23.4, js["user"]["home"]["lon"]
          assert_equal 3, js["user"]["home"]["zoom"]
        else
          assert_nil js["user"]["home"]
        end

        if include_private && user.languages.present?
          assert_equal user.languages, js["user"]["languages"]
        else
          assert_nil js["user"]["languages"]
        end

        if include_private
          assert_equal user.messages.count, js["user"]["messages"]["received"]["count"]
          assert_equal 0, js["user"]["messages"]["received"]["unread"]
          assert_equal user.sent_messages.count, js["user"]["messages"]["sent"]["count"]
        else
          assert_nil js["user"]["messages"]
        end

        if include_email
          assert_equal user.email, js["user"]["email"]
        else
          assert_nil js["user"]["email"]
        end
      end
    end
  end
end
