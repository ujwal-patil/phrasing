module Phrasing
  class WordCounter

    def initialize
      @added_words = 0
      @removed_words = 0
    end

    attr_reader :added_words, :removed_words

    def update(old_text, new_text)
      old_text = old_text.to_s
      new_text = new_text.to_s

      plus_words(new_text.split - old_text.split)
      minus_words(old_text.split - new_text.split)
    end

    def plus_words(words)
      @added_words += words.length
    end

    def minus_words(words)
      @removed_words += words.length
    end

    def has_change?
      !(@added_words.zero? && removed_words.zero?)
    end

  end
end
