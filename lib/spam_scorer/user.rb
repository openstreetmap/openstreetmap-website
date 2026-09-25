# frozen_string_literal: true

module SpamScorer
  class User
    def initialize(user)
      @user = user
    end

    def score
      changeset_score = user.changesets.size * 50
      trace_score = user.traces.size * 50
      diary_entry_score = user.diary_entries.visible.inject(0) { |acc, elem| acc + SpamScorer.new_from_rich_text(elem.body).score }
      diary_comment_score = user.diary_comments.visible.inject(0) { |acc, elem| acc + SpamScorer.new_from_rich_text(elem.body).score }
      report_score = Report.where(:category => "spam", :issue => user.issues.with_status("open")).distinct.count(:user_id) * 20

      score = SpamScorer.new_from_rich_text(user.description).score / 4.0
      score += user.diary_entries.visible.where("created_at > ?", 1.day.ago).count * 10
      score += diary_entry_score / user.diary_entries.visible.length unless user.diary_entries.visible.empty?
      score += diary_comment_score / user.diary_comments.visible.length unless user.diary_comments.visible.empty?
      score += report_score
      score -= changeset_score
      score -= trace_score

      score.to_i
    end

    private

    attr_reader :user
  end
end
