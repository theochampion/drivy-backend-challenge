# compare results (ignoring whitespaces)
ruby main.rb && diff -b ./data/output.json ./data/expected_output.json