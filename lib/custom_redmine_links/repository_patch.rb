Repository.class_eval do
  safe_attributes 'extra_remote_pull_request_url'

  def extra_remote_pull_request_url(pull_request_id = nil)
    info = extra_info || {}
    url = info['extra_remote_pull_request_url'] || ''
    return url unless pull_request_id.present?
    url.sub(':pull_request_id', pull_request_id)
  end

end
