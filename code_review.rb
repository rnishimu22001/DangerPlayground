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
            puts info.patch
            warn("Detected Word: " +  info.keywords.join(","), file: info.file_path, line: info.line_number)
        end

        def review(file_path, keywords)
            git_file_info = git.diff_for_file(file_path)
            ReviewInfo(file_path, 0, [], git_file_info.patch)
        end
    end
end
