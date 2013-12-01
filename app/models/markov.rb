require 'yaml'

class MarkovSourcePhrase
  attr_accessor :title, :source_id
  def initialize(title, source_id)
    self.title = title
    self.source_id = source_id
  end
  def ==(object)
    if object.equal?(self)
     return true
    elsif !self.class.equal?(object.class)
     return false
    end
    return self.title == object.title
  end
  def hash
    self.title.hash
  end
  alias_method :eql?, :==
end

class MarkovFragment
  attr_accessor :fragment, :source_phrase
  def initialize(fragment, source_phrase)
    self.fragment = fragment
    self.source_phrase = source_phrase
  end
  def ==(object)
    if object.equal?(self)
     return true
    elsif !self.class.equal?(object.class)
     return false
    end
    return self.fragment == object.fragment
  end
  def hash
    self.fragment.hash
  end
  alias_method :eql?, :==
end

class Markov

  @markov_map = {}
  @lookback = 2
  @source_phrases = []

  attr_reader :markov_map

  def initialize(source_sentences, source_id)
    hls = source_sentences.map{|s| MarkovSourcePhrase.new(s, source_id) }
    build_map! hls
  end

  def build_map!(source_phrases, lookback = 2)
    @source_phrases = source_phrases
    @lookback = lookback

    markov_map = {}

    # Generate map in the form word1 -> word2 -> occurences of word2 after word1
    @source_phrases.each do |phrase|
      title = phrase.title.split
      if title.length > lookback
        (title.length + 1).times do |i|
          a = MarkovFragment.new(title[([0, i - lookback].max)...i].join(' '), phrase)
          b = MarkovFragment.new(title[i...i+1].join(' '), phrase)
          markov_map[a]    = {} if markov_map[a].nil?
          markov_map[a][b] = 0 if markov_map[a][b].nil?
          markov_map[a][b] = markov_map[a][b] + 1
        end
      end
    end

    # Convert map to the word1 -> word2 -> probability of word2 after word1
    markov_map.each do |fragment, following|
      total = following.values.reduce(:+).to_f # sum
      following.each_key do |key|
        following[key] /= total
      end
    end

    @markov_map = markov_map

  end

  # Typical sampling from a categorical distribution
  def markov_sample(items)
    items = {} unless items
    next_word = nil
    t = 0.0
    items.each do |k, v|
      t += v
      next_word = k if t > 0 && rand() < v / t
    end
    next_word
  end

  def get_sentence(length_max = 140)
    mapkeys = @markov_map.keys.map(&:fragment)
    while true
      sentence = []
      next_word = mapkeys.sample
      while next_word != '' && next_word != nil
        sentence << next_word
        frag = markov_sample(@markov_map[MarkovFragment.new(sentence.last(@lookback).join(' '), nil)])
        next_word = frag ? frag.fragment : nil
      end
      sentence = sentence.join(' ')

      # Prune titles that are substrings of actual titles
      next if @source_phrases.any?{|phrase| phrase.title.include?(sentence) }

      next if sentence.length > length_max

      return sentence
    end
  end

end

# path = File.expand_path("../../../lib/dictionaries/hackernews.txt", __FILE__)
# sources = File.readlines(path).map{|l| l.chomp.strip}

# markov = Markov.new(sources, 'hackernews')

# puts "=== genny ==="

# 10.times { puts markov.get_sentence }