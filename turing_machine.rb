# "Regex implementation" of a Turing Machine
#
# This program will read a "machine definition", turn it into a Mega Regex,
# initialize a tape with the machine head and the input,
# and then run a Turing Machine using that regex alone.
#
# When run, this will output the mega-regex it's using to `mega_regex.txt`,
# so you can see what it's doing.



# `MachineDefinition`: Takes a machine definition (array of State Transition strings),
# parses those state transitions, and generates
# - a mega_regex for the machine
# - an initial tape for the input, plus the machine head
class MachineDefinition
  TAPE_LENGTH = 100
  EMPTY_CHAR = "_"

  attr_reader :parsed_transitions

  def initialize(state_transitions)
    @state_transitions = state_transitions
    @parsed_transitions = state_transitions.map { |txn| parse_transition(txn) }
  end

  # Parses a state transition for a machine, and returns a hash with its parts
  # State Transitions take the form:
  # "Q{match_state}:{match_char}/{new_char}->{L|R}:Q{new_state}"
  def parse_transition(txn)
    captures = /(Q\d+):(\w)\/(\w)->(R|L):(Q\d+)/.match(txn).captures
    parts = [:match_state, :match_char, :new_char, :head_direction, :new_state]
    parts.zip(captures).to_h
  end

  # Returns an array of all the possible states for our state machine
  def possible_states
    parsed_transitions.map { |txn| [txn[:match_state], txn[:new_state]] }.flatten.uniq
  end

  # Returns an array of all the possible chars we can find in our tape
  def possible_chars
    @possible_chars ||=
        parsed_transitions.map { |txn| [txn[:match_char], txn[:new_char]] }.flatten.uniq
  end

  # Here is where the magic happens.
  # Our replace regex looks like this: \k<new_left>#{states}:{possible_chars}\k<new_state>:\k<new_cursor>#\k<new_right>
  #
  # What we do here is set the right values for the 4 named captures:
  #   `new_left`, `new_state`, `new_cursor` and `new_right`.
  #
  # The `new_left`, `new_cursor` and `new_right` captures are what make the head move left and right.
  # Depending on what we capture in them, we go one way or the other.
  #
  # Let's imagine for a second we're not changing the contents of the tape.
  # Then we move:
  # - left by setting `new_left` to nothing,
  #                   `new_cursor` to what's left of the head, and
  #                   `new_right` to what's under the cursor.
  # - right by setting `new_left` to what's under the cursor,
  #                    `new_cursor` to what's right of the head, and
  #                    `new_right` to nothing.
  #
  # Now, because we *do* write to the tape, we need to capture the right character in the
  # `possible_chars` section of our head, and set that for `new_left` or `new_right`, rather
  # than what's currently under the cursor.
  #
  # We also need to change state, so we capture the right state in the `possible_states`
  # section of the head, and name that `new_state`.
  def regex_clauses
    parsed_transitions.map do |txn|
      if txn[:head_direction] == "R"
        "#" + possible_states.map { |state| state == txn[:new_state] ? "(?<new_state>#{state})" : state }.join("") +
          ":" + possible_chars.map { |char| char == txn[:new_char] ? "(?<new_left>#{char})" : char }.join("") +
          "-#{ txn[:match_state] }:#{ txn[:match_char] }" +
          "#(?<new_cursor>\\w)"
      else
        "(?<new_cursor>\\w)" +
          "#" + possible_states.map { |state| state == txn[:new_state] ? "(?<new_state>#{state})" : state }.join("") +
          ":" + possible_chars.map { |char| char == txn[:new_char] ? "(?<new_right>#{char})" : char }.join("") +
          "-#{ txn[:match_state] }:#{ txn[:match_char] }" +
          "#"
      end
    end
  end

  # This is a constant for all the definitions, but it recreates the entire head every time,
  # so it needs to include all the states and tape chars, which is why it's generated
  # dynamically
  def replace_regex
    "\\k<new_left>" +
        "#" + possible_states.join("") +
        ":" + possible_chars.join("") +
        "-\\k<new_state>:\\k<new_cursor>" +
        "#\\k<new_right>"
  end

  # {left half of the tape}#{possible_states}:{possible_chars}-{current state}:{current char}#{right half of the tape}
  def initial_tape(input)
    initial_state = possible_states.first

    EMPTY_CHAR * (TAPE_LENGTH / 2) +
        "#" + possible_states.join("") +
        ":" + possible_chars.join("") +
        "-" + initial_state + ":" + input.chars.first +
        "#" + input[1, input.length] +
        EMPTY_CHAR * (TAPE_LENGTH / 2)
  end

  def generate_regex_and_save!
    clauses = regex_clauses
    save_regex(clauses)

    regex_string = clauses.map { |c| "(#{c})" }.join("|")
    Regexp.new(regex_string)
  end

  # Dump the regex clause for each machine definition line,
  # together with the definition itself as a comment, to `mega_regex.txt`
  def save_regex(clauses)
    longest_line_length = clauses.map(&:length).max
    mega_regex_file_lines = clauses.map.with_index do |clause, i|
      "#{clause.ljust(longest_line_length + 3)} # #{@state_transitions[i]}"
    end

    File.open("mega_regex.txt", "w+") do |f|
      f.puts "Regex Clauses:"
      mega_regex_file_lines.each { |line| f.puts(line) }
      f.puts ""
      f.puts "Replace Regex:"
      f.puts replace_regex
      f.puts ""
      f.puts "Initial Tape:"
      f.puts initial_tape("TAPEINPUT")
    end
  end
end

#==================================================================================
# Example machine definitions

# Detect language: a^nb^oc^p -> x*o == p
# https://www.geeksforgeeks.org/construct-a-turing-machine-for-l-aibjck-ij-k-i-j-k-%e2%89%a5-1/?ref=lbp
# that is: aabbcccc
# that is: aabbbcccccc
A_TIMES_B_EQUALS_C_STATE_TRANSITIONS = [
  "Q0:a/X->R:Q1",
  "Q0:b/b->R:Q5",
  "Q1:a/a->R:Q1",
  "Q1:b/Y->R:Q2",
  "Q1:Z/Z->L:Q4",
  "Q2:Z/Z->R:Q2",
  "Q2:b/b->R:Q2",
  "Q2:c/Z->L:Q3",
  "Q3:Z/Z->L:Q3",
  "Q3:b/b->L:Q3",
  "Q3:Y/Y->R:Q1",
  "Q4:a/a->L:Q4",
  "Q4:Y/b->L:Q4",
  "Q4:X/X->R:Q0",
  "Q5:Z/Z->R:Q5",
  "Q5:b/b->R:Q5",
  "Q5:F/F->L:Q6",
]

A_TIMES_B_EQUALS_C_INPUT = "aabbbccccccF"  # Valid (ends at Q6)
# A_TIMES_B_EQUALS_C_INPUT = "aabbbcccccF"   # Invalid (short, gets stuck at Q2)
# A_TIMES_B_EQUALS_C_INPUT = "aabbbcccccccF" # Invalid (long, gets stuck at Q5)

#--------------------------------------------------

# Duplicate a string of 0's & 1's (delimited by 'B')
# https://www.geeksforgeeks.org/turing-machine-for-copying-data/
DUPLICATE_BINARY_STRING_STATE_TRANSITIONS = [
  "Q0:B/B->R:Q1", # Skip the first B

  "Q1:0/0->R:Q1", # Find a B, replace with a C, move to Q1
  "Q1:1/1->R:Q1",
  "Q1:B/C->L:Q2",

  "Q2:0/0->L:Q2", # Rewind until find the initial B, an X or a Y
  "Q2:1/1->L:Q2",
  "Q2:C/C->L:Q2",
  "Q2:B/B->R:Q3",
  "Q2:X/X->R:Q3",
  "Q2:Y/Y->R:Q3",

  "Q3:0/X->R:Q10", # Replace a 0 with X, and move to Q3 (Q3 copies a 0 at the end)
  "Q3:1/Y->R:Q20", # Replace a 1 with Y, and move to Q?? (Q?? copies a 1 at the end)
  "Q3:C/B->L:Q30", # If we find a C, we're done copying, re-replace first number with 0's and 1's

  "Q10:0/0->R:Q10", # Move right until end of tape
  "Q10:1/1->R:Q10",
  "Q10:C/C->R:Q10",
  "Q10:_/0->L:Q2", # Q1 rewind

  "Q20:0/0->R:Q20", # Move right until end of tape
  "Q20:1/1->R:Q20",
  "Q20:C/C->R:Q20",
  "Q20:_/1->L:Q2", # Q1 rewind

  "Q30:X/0->L:Q30", # Rewind until find the initial B
  "Q30:Y/1->L:Q30",
  "Q30:B/B->L:Q99", # HALT
]

DUPLICATE_BINARY_STRING_INPUT = "B00101100000011B"

#==================================================================================
# Actual runner code
MACHINE_DEFINITION = DUPLICATE_BINARY_STRING_STATE_TRANSITIONS
INPUT = DUPLICATE_BINARY_STRING_INPUT

machine = MachineDefinition.new(MACHINE_DEFINITION)
initial_tape = machine.initial_tape(INPUT)
regex = machine.generate_regex_and_save!
replace_regex = machine.replace_regex

new_tape = initial_tape
tape = ""

while (tape != new_tape) # Crappy HALT condition
  puts tape = new_tape
  new_tape = tape.gsub(regex, replace_regex)
  # sleep 0.018 # Gives a nice animation speed for the Keynote
end

puts ""
puts "Input: #{ initial_tape }"
puts "Output: #{ new_tape }"
