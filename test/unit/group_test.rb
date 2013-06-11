# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class GroupTest < ActiveSupport::TestCase
  api_fixtures
  fixtures :groups, :users

  def test_group_count
    assert_equal 2, Group.count
  end

  def test_group_membership
    uk_group = Group.find(1)
    us_group = Group.find(2)
    first_user = User.find(1)
    second_user = User.find(2)

    uk_group.users << first_user
    uk_group.users << second_user
    us_group.users << second_user

    assert arrays_are_equal?(uk_group.users.map(&:id), [first_user.id, second_user.id])
    assert arrays_are_equal?(us_group.users.map(&:id), [second_user.id])
    assert arrays_are_equal?(first_user.groups.map(&:id), [uk_group.id])
    assert arrays_are_equal?(second_user.groups.map(&:id), [uk_group.id, us_group.id])
  end

private

  def arrays_are_equal?(a, b)
    a.sort.uniq == b.sort.uniq
  end
end
