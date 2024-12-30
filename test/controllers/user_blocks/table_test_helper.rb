module UserBlocks
  module TableTestHelper
    private

    def check_user_blocks_table(user_blocks)
      assert_dom "table#block_list tbody tr" do |rows|
        assert_equal user_blocks.count, rows.count, "unexpected number of rows in user blocks table"
        rows.zip(user_blocks).map do |row, user_block|
          assert_dom row, "a[href='#{user_block_path user_block}']", 1
        end
      end
    end

    def check_no_page_link(name)
      assert_select "a.page-link", { :text => /#{Regexp.quote(name)}/, :count => 0 }, "unexpected #{name} page link"
    end

    def check_page_link(name)
      assert_select "a.page-link", { :text => /#{Regexp.quote(name)}/ }, "missing #{name} page link" do |buttons|
        return buttons.first.attributes["href"].value
      end
    end
  end
end
