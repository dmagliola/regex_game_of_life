# "Regex implementation" of Game of Life, v1 (intermediate step)
#
# This version uses a Mega-Regex to find all the cells that need to change,
# but uses a Ruby block to "flip" each cell, instead of being fully Regex-based.
#
# When run, this will output the mega-regex it's using to `mega_regex.txt`,
# so you can see what it's doing, then run the game based on that Regex.

# "Board" helpers, mostly to deal with loading from files, and printing to screen.
# In "Regex game of life", we're representing the board as linear string of 0's and 1's
class Board
  # Loads an input pattern of 0's and 1's to use as an initial board
  def self.load_pattern(filename)
    lines = IO.readlines(filename)
    lines.map(&:strip).join("")
  end

  # Given a filename containing a board, return the board width and height
  def self.pattern_board_size(filename)
    lines = IO.readlines(filename)
    {
      w: lines.first.strip.length,
      h: lines.reject(&:empty?).compact.length
    }
  end

  # Given a linear string representing the board, print it to screen
  # with spaces and squares, to make it look nice and understandable
  def self.print(board, board_width)
    puts "\e[H\e[2J" # Clear the screen
    board = board.gsub("0", " ").gsub("1", "█")
    lines = board.scan(/.{1,#{board_width}}/)
    lines.each {|line| puts line }
  end
end

# Generator of the Mega-Regex we'll use to run the game.
class MegaRegex
  # Yields all the combinations of cells and their neighbours where the middle cell needs
  # to change (either spawn or die)
  def self.all_changing_combos
    (0...512).each do |i|
      binary = i.to_s(2).rjust(9, "0")
      alive = binary[4].to_i

      neighbours = binary.chars.count{|d| d == "1" }
      neighbours -= 1 if alive == 1

      if (alive == 1 && neighbours != 2 && neighbours != 3) ||
        (alive == 0 && neighbours == 3)
        yield binary
      end
    end
  end

  # Generates all the clauses for each possible cell state change,
  # returns array of strings with each clause.
  def self.mega_regex_clauses
    clauses = []
    MegaRegex.all_changing_combos do |changed_cell|
      chars = changed_cell.chars

      top_row = chars.shift(3).join("")
      middle_row = chars.shift(3)
      bottom_row = chars.join("")

      clauses <<
        "(?<=#{top_row}(?:.{BOARD_SIZE})\
        #{middle_row[0]})#{middle_row[1]}(?=#{middle_row[2]}\
        (?:.{BOARD_SIZE})#{ bottom_row })".
        gsub(/\s/,"")
    end
    clauses
  end

  # Generates the Regex to run the game, saves its individual clauses to `mega_regex.txt`,
  # and returns the actual Regex instance we'll use to run the game.
  def self.generate_and_save!(board_width)
    clauses = MegaRegex.mega_regex_clauses

    File.open("mega_regex.txt", "w+") do |f|
      clauses.each { |line| f.puts(line) }
    end

    regex_string = clauses.join("|")
    regex_string = regex_string.gsub("BOARD_SIZE", (board_width - 3).to_s)
    Regexp.new(regex_string)
  end
end

# Game "Logic"
class GameOfLife
  def self.game_loop(board, mega_regex, board_width)
    while true
      Board.print(board, board_width)
      board.gsub!(mega_regex) { |m| m == "0" ? "1" : "0" } # Almost, but we have a cheaty block here!
    end
  end
end

# Loading the board / bootstrapping
INPUT_FILENAME = "input_pattern.txt"
board = Board.load_pattern(INPUT_FILENAME)
board_size = Board.pattern_board_size(INPUT_FILENAME)
mega_regex = MegaRegex.generate_and_save!(board_size[:w])
GameOfLife.game_loop(board, mega_regex, board_size[:w])
