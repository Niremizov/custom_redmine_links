# patch for ApplicationHelper

module ApplicationHelper
  # Redmine links
  #
  # Examples:
  #   Issues:
  #     #52 -> Link to issue #52
  #   Changesets:
  #     r52 -> Link to revision 52
  #     commit:a85130f -> Link to scmid starting with a85130f
  #   Documents:
  #     document#17 -> Link to document with id 17
  #     document:Greetings -> Link to the document with title "Greetings"
  #     document:"Some document" -> Link to the document with title "Some document"
  #   Versions:
  #     version#3 -> Link to version with id 3
  #     version:1.0.0 -> Link to version named "1.0.0"
  #     version:"1.0 beta 2" -> Link to version named "1.0 beta 2"
  #   Attachments:
  #     attachment:file.zip -> Link to the attachment of the current object named file.zip
  #   Source files:
  #     source:some/file -> Link to the file located at /some/file in the project's repository
  #     source:some/file@52 -> Link to the file's revision 52
  #     source:some/file#L120 -> Link to line 120 of the file
  #     source:some/file@52#L120 -> Link to line 120 of the file's revision 52
  #     export:some/file -> Force the download of the file
  #   Forum messages:
  #     message#1218 -> Link to message with id 1218
  #  Projects:
  #     project:someproject -> Link to project named "someproject"
  #     project#3 -> Link to project with id 3
  #
  #   Links can refer other objects from other projects, using project identifier:
  #     identifier:r52
  #     identifier:document:"Some document"
  #     identifier:version:1.0.0
  #     identifier:source:some/file
  def parse_redmine_links(text, default_project, obj, attr, only_path, options)
    # ADDED pull request below.
    text.gsub!(%r{<a( [^>]+?)?>(.*?)</a>|([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-_]+):)?(pull request |attachment|document|version|forum|news|message|project|commit|source|export)?(((#)|((([a-z0-9\-_]+)\|)?(r)))((\d+)((#note)?-(\d+))?)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]][^A-Za-z0-9_/])|,|\s|\]|<|$)}) do |m|
      tag_content, leading, esc, project_prefix, project_identifier, prefix, repo_prefix, repo_identifier, sep, identifier, comment_suffix, comment_id = $2, $3, $4, $5, $6, $7, $12, $13, $10 || $14 || $20, $16 || $21, $17, $19
      if tag_content
        $&
      else
        link = nil
        project = default_project
        if project_identifier
          project = Project.visible.find_by_identifier(project_identifier)
        end
        if esc.nil?
          if prefix.nil? && sep == 'r'
            if project
              repository = nil
              if repo_identifier
                repository = project.repositories.detect {|repo| repo.identifier == repo_identifier}
              else
                repository = project.repository
              end
              # project.changesets.visible raises an SQL error because of a double join on repositories
              if repository &&
                   (changeset = Changeset.visible.
                                    find_by_repository_id_and_revision(repository.id, identifier))
                link = link_to(h("#{project_prefix}#{repo_prefix}r#{identifier}"),
                               {:only_path => only_path, :controller => 'repositories',
                                :action => 'revision', :id => project,
                                :repository_id => repository.identifier_param,
                                :rev => changeset.revision},
                               :class => 'changeset',
                               :title => truncate_single_line_raw(changeset.comments, 100))
              end
            end
          elsif sep == '#'
            oid = identifier.to_i
            case prefix
            when nil
              if oid.to_s == identifier &&
                issue = Issue.visible.find_by_id(oid)
                anchor = comment_id ? "note-#{comment_id}" : nil
                link = link_to("##{oid}#{comment_suffix}",
                               issue_url(issue, :only_path => only_path, :anchor => anchor),
                               :class => issue.css_classes,
                               :title => "#{issue.tracker.name}: #{issue.subject.truncate(100)} (#{issue.status.name})")
              end
            when 'pull request '
              # Special handling for PULL REQUEST
              repository = nil
              if obj.respond_to?(:repository)
                repository = obj.repository
              else
                repository = project.repository
              end
              if repository && repository.extra_remote_pull_request_url.present? 
                link = link_to("pull request ##{oid}", repository.extra_remote_pull_request_url(identifier), { title: "Pull Request ##{oid}", target: '_blank' })
              end
            when 'document'
              if document = Document.visible.find_by_id(oid)
                link = link_to(document.title, document_url(document, :only_path => only_path), :class => 'document')
              end
            when 'version'
              if version = Version.visible.find_by_id(oid)
                link = link_to(version.name, version_url(version, :only_path => only_path), :class => 'version')
              end
            when 'message'
              if message = Message.visible.find_by_id(oid)
                link = link_to_message(message, {:only_path => only_path}, :class => 'message')
              end
            when 'forum'
              if board = Board.visible.find_by_id(oid)
                link = link_to(board.name, project_board_url(board.project, board, :only_path => only_path), :class => 'board')
              end
            when 'news'
              if news = News.visible.find_by_id(oid)
                link = link_to(news.title, news_url(news, :only_path => only_path), :class => 'news')
              end
            when 'project'
              if p = Project.visible.find_by_id(oid)
                link = link_to_project(p, {:only_path => only_path}, :class => 'project')
              end
            end
          elsif sep == ':'
            # removes the double quotes if any
            name = identifier.gsub(%r{^"(.*)"$}, "\\1")
            name = CGI.unescapeHTML(name)
            case prefix
            when 'document'
              if project && document = project.documents.visible.find_by_title(name)
                link = link_to(document.title, document_url(document, :only_path => only_path), :class => 'document')
              end
            when 'version'
              if project && version = project.versions.visible.find_by_name(name)
                link = link_to(version.name, version_url(version, :only_path => only_path), :class => 'version')
              end
            when 'forum'
              if project && board = project.boards.visible.find_by_name(name)
                link = link_to(board.name, project_board_url(board.project, board, :only_path => only_path), :class => 'board')
              end
            when 'news'
              if project && news = project.news.visible.find_by_title(name)
                link = link_to(news.title, news_url(news, :only_path => only_path), :class => 'news')
              end
            when 'commit', 'source', 'export'
              if project
                repository = nil
                if name =~ %r{^(([a-z0-9\-_]+)\|)(.+)$}
                  repo_prefix, repo_identifier, name = $1, $2, $3
                  repository = project.repositories.detect {|repo| repo.identifier == repo_identifier}
                else
                  repository = project.repository
                end
                if prefix == 'commit'
                  if repository && (changeset = Changeset.visible.where("repository_id = ? AND scmid LIKE ?", repository.id, "#{name}%").first)
                    link = link_to h("#{project_prefix}#{repo_prefix}#{name}"), {:only_path => only_path, :controller => 'repositories', :action => 'revision', :id => project, :repository_id => repository.identifier_param, :rev => changeset.identifier},
                                                 :class => 'changeset',
                                                 :title => truncate_single_line_raw(changeset.comments, 100)
                  end
                else
                  if repository && User.current.allowed_to?(:browse_repository, project)
                    name =~ %r{^[/\\]*(.*?)(@([^/\\@]+?))?(#(L\d+))?$}
                    path, rev, anchor = $1, $3, $5
                    link = link_to h("#{project_prefix}#{prefix}:#{repo_prefix}#{name}"), {:only_path => only_path, :controller => 'repositories', :action => (prefix == 'export' ? 'raw' : 'entry'), :id => project, :repository_id => repository.identifier_param,
                                                            :path => to_path_param(path),
                                                            :rev => rev,
                                                            :anchor => anchor},
                                                           :class => (prefix == 'export' ? 'source download' : 'source')
                  end
                end
                repo_prefix = nil
              end
            when 'attachment'
              attachments = options[:attachments] || []
              attachments += obj.attachments if obj.respond_to?(:attachments)
              if attachments && attachment = Attachment.latest_attach(attachments, name)
                link = link_to_attachment(attachment, :only_path => only_path, :download => true, :class => 'attachment')
              end
            when 'project'
              if p = Project.visible.where("identifier = :s OR LOWER(name) = :s", :s => name.downcase).first
                link = link_to_project(p, {:only_path => only_path}, :class => 'project')
              end
            end
          end
        end
        (leading + (link || "#{project_prefix}#{prefix}#{repo_prefix}#{sep}#{identifier}#{comment_suffix}"))
      end
    end
  end
end
