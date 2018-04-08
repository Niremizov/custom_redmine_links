# patch for RepositoriesHelper

RepositoriesHelper.class_eval do
  alias_method :orig_repository_field_tags, :repository_field_tags
  def repository_field_tags(form, repository)
    html = orig_repository_field_tags(form, repository)
    html += extra_remote_pull_request_url_tag(form)
    html
  end

  def add_remote_pull_request_link(html)
    return html unless @repository.identifier.present?
    link =  link_to_web_revision(@changeset, @changeset.repository)
    return html unless link.present?
    revision_link = "#{@rev} (#{link})".html_safe
    html.sub(content_tag(:td, @rev), content_tag(:td, revision_link)).html_safe
  end

  private

  def extra_remote_pull_request_url_tag(form)
    content_tag('p', form.text_field('extra_remote_pull_request_url', size: 60) +
                 '<br />'.html_safe +
                 content_tag(:em, l(:field_extra_remote_pull_request_url_info).html_safe, class: 'info')
    )
  end

end
