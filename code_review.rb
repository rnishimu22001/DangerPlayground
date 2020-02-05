module Danger
    class CodeReview < Plugin

        ReviewInfo = Struct.new(:file_path, :line_number, :keywords, :patch)

        def code_review
            # レビューで引っ掛けたいキーワード
            keywords = ["マージ禁止", "TODO"]
            # gitモジュールから変更されたファイルパスを取得する
            file_paths = git.modified_files + git.added_files
            file_paths.each { |path|
                results = review(path, keywords)
                results.each { |info|
                    submit_warn(info)
                }
            }
        end

        def submit_warn(info)
            # https://github.com/danger/danger/blob/master/lib/danger/danger_core/plugins/dangerfile_messaging_plugin.rb#L63
            # lineとfileを指定すると、インラインコメントができる！
            puts info
            warn("Detected Word: " +  info.keywords[0], file: info.file_path, line: info.line_number)
        end

        def review(file_path, keywords)
            git_info = git.diff_for_file(file_path)
            info = []
            git_start_line = /^@@ .+\+(?<line_number>\d+),/ 
            # objective-Cのstaticメソッドもひっかかりそう....
            git_modified_line = /^\+/
            line_number = 0
            git_info.patch.split("\n").each do |line|
                start_line_number = 0
                case line
                when git_start_line
                    start_line_number = Regexp.last_match[:line_number].to_i
                end
                if line_number > 0 then
                    line_number += 1
                elsif start_line_number > 0 && line_number == 0 then
                    line_number = start_line_number
                else
                    next
                end
                modified_line = line.match(git_modified_line)
                if modified_line.nil? then
                    puts "not modified"
                    next
                end
                puts "modified"
                matched = line.match(Regexp.union(keywords))
                if !matched.nil? then
                    puts "detected"
                    info << ReviewInfo.new(file_path, line_number, matched.to_a, git_info.patch)
                end
            end
            info
        end
    end
end
