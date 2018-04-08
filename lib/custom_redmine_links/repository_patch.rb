Repository.class_eval do
  safe_attributes 'extra_remote_pull_request_url'

  def extra_remote_pull_request_url(pull_request_id = nil)
    url = safe_extra_info[:extra_remote_pull_request_url] || ''
    return url unless pull_request_id.present?
    url.sub(':pull_request_id', pull_request_id)
  end

  def extra_remote_pull_request_url=(arg)
    merge_extra_info :extra_remote_pull_request_url => arg
  end
  
end
