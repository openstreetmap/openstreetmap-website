class Issue < ActiveRecord::Base
	belongs_to :reportable, :polymorphic => true
	has_many :reports
	validates :reportable_id, :uniqueness => { :scope => [ :reportable_type ] }

	# Check if more statuses are needed
	enum status: %w( open ignored resolved )

	scope :with_status, -> (issue_status) { where(:status => statuses[issue_status])}

	def read_reports
		resolved_at.present? ? reports.where("created_at < ?", resolved_at) : nil
	end

	def unread_reports
    resolved_at.present? ? reports.where("created_at >= ?", resolved_at) : reports
	end

	include AASM
	aasm :column => :status, :no_direct_assignment => true do
		state :open, :initial => true
		state :ignored
		state :resolved

		event :ignore do
			transitions :from => :open, :to => :ignored 
		end

		event :resolve do
			transitions :from => :open, :to => :resolved
			after do
				self.resolved_at = Time.now.getutc
			end
		end

		event :reopen do
			transitions :from => :resolved, :to => :open
		end

	end

end
