#patch for Changeset

Changeset.class_eval do
  TIMELOG_RE = /
    (
    ((\d+)(h|hours?))((\d+)(m|min)?)?
    |
    ((\d+)(h|hours?|m|min))
    |
    (\d+):(\d+)
    |
    (\d+([\.,]\d+)?)h?
    )
    /x

  alias_method :scan_comment_for_issue_ids_orig, :scan_comment_for_issue_ids
  def scan_comment_for_issue_ids
    return if comments.blank?
    # keywords used to reference issues
    ref_keywords = Setting.commit_ref_keywords.downcase.split(",").collect(&:strip)
    ref_keywords_any = ref_keywords.delete('*')
    # keywords used to fix issues
    fix_keywords = Setting.commit_update_keywords_array.map {|r| r['keywords']}.flatten.compact

    kw_regexp = (ref_keywords + fix_keywords).collect{|kw| Regexp.escape(kw)}.join("|")

    referenced_issues = []

    #CHANGED REGEXP to #?, so # is not nessary to use.
    comments.scan(/([\s\(\[,-]|^)((#{kw_regexp})[\s:]+)?(#?\d+(\s+@#{TIMELOG_RE})?([\s,;&]+#\d+(\s+@#{TIMELOG_RE})?)*)(?=[[:punct:]]|\s|<|$)/i) do |match|
      action, refs = match[2].to_s.downcase, match[3]
      next unless action.present? || ref_keywords_any

      #CHANGED REGEXP to #?, so # is not nessary to use.
      refs.scan(/#?(\d+)(\s+@#{TIMELOG_RE})?/).each do |m|
        issue, hours = find_referenced_issue_by_id(m[0].to_i), m[2]
        if issue && !issue_linked_to_same_commit?(issue)
          referenced_issues << issue
          # Don't update issues or log time when importing old commits
          unless repository.created_on && committed_on && committed_on < repository.created_on
            fix_issue(issue, action) if fix_keywords.include?(action)
            log_time(issue, hours) if hours && Setting.commit_logtime_enabled?
          end
        end
      end
    end

    referenced_issues.uniq!
    self.issues = referenced_issues unless referenced_issues.empty?
  end

end