module Sdust
  module Core
    extend self

    WordLength = 3
    WordTotal  = 1 << (3 << 1)
    WordMask   = WordTotal - 1

    struct PerfectInterval
      getter start : Int32
      getter finish : Int32
      getter repeat : Int32
      getter length : Int32

      def initialize(@start, @finish, @repeat, @length)
      end
    end

    def sdust(sequence : String | IO::Memory, win_size : Int32, threshold : Int32)
      repeat_value = 0
      repeat_window = 0
      win_len = 0
      curr_value = Array(Int32).new(WordTotal, 0)
      curr_window = Array(Int32).new(WordTotal, 0)
      start = 0    # start of the current window
      cont_len = 0 # length of a contiguous A/C/G/T (sub)sequence
      curr_word = 0

      perfect_intervals = [] of PerfectInterval
      result = [] of UInt64
      window = [] of Int32

      seq_bytes = ReadFasta.normalize_sequence(sequence)
      seq_bytes.each_with_index do |b, i|
        if b < 4 # an A/C/G/T base
          cont_len += 1
          curr_word = (curr_word << 2 | b) & (WordTotal - 1)
          if (cont_len >= WordLength) # we have seen a word
            # set the start of the current window
            start = (cont_len - win_size > 0 ? cont_len - win_size : 0) + (i + 1 - cont_len)
            # save intervals falling out of the current window?
            save_masked_regions(result, perfect_intervals, start)
            win_len, repeat_window, repeat_value = \
               shift_window(curr_word, window, threshold, win_size, win_len, repeat_window, repeat_value, curr_window, curr_value)
            if (repeat_window * 10 > win_len * threshold)
              find_perfect(perfect_intervals, window, threshold, start, win_len, repeat_value, curr_value)
            end
          end
        else # N or the end of sequence; N effectively breaks input into pieces of independent sequences
          start = (cont_len - win_size + 1 > 0 ? cont_len - win_size + 1 : 0) + (i + 1 - cont_len)
          # clear up unsaved perfect intervals
          while (!perfect_intervals.empty?)
            save_masked_regions(result, perfect_intervals, start)
            start += 1
          end
          perfect_intervals.clear
          cont_len = 0
          curr_word = 0
        end
      end
      start = (cont_len - win_size + 1 > 0 ? cont_len - win_size + 1 : 0) + (seq_bytes.size + 1 - cont_len)
      # clear up unsaved perfect intervals
      while (!perfect_intervals.empty?)
        save_masked_regions(result, perfect_intervals, start)
        start += 1
      end
      return result
    end

    def shift_window(
      curr_word : Int32, window : Array(Int32), threshold : Int32, win_size : Int32,
      win_len : Int32, repeat_window : Int32, repeat_value : Int32,
      curr_window : Array(Int32), curr_value : Array(Int32)
    )
      if window.size >= win_size - WordLength + 1
        s = window.shift
        curr_window[s] -= 1; repeat_window -= curr_window[s]
        if win_len > window.size
          win_len -= 1; curr_value[s] -= 1; repeat_value -= curr_value[s]
        end
      end

      window.push(curr_word)
      win_len += 1
      repeat_window += curr_window[curr_word]; curr_window[curr_word] += 1
      repeat_value += curr_value[curr_word]; curr_value[curr_word] += 1

      if curr_value[curr_word] * 10 > (threshold << 1)
        loop do
          s = window[window.size - win_len]
          curr_value[s] -= 1; repeat_value -= curr_value[s]
          win_len -= 1
          break if s == curr_word
        end
      end

      return win_len, repeat_window, repeat_value
    end

    def save_masked_regions(
      result : Array(UInt64),
      perfect_intervals : Array(PerfectInterval),
      start : Int32
    )
      saved = false
      return if perfect_intervals.empty?
      last_interval = perfect_intervals.last
      return if last_interval.start >= start

      unless result.empty?
        last_result = result.last
        s = (last_result >> 32)
        f = last_result.unsafe_as(UInt32)
        if (last_interval.start <= f)
          saved = true
          result[-1] = (s.to_u64 << 32) | (f > last_interval.finish ? f : last_interval.finish)
        end
      end
      unless saved
        result << ((last_interval.start.to_u64 << 32) | last_interval.finish)
      end
      perfect_intervals.select! { |i| i.start >= start }
    end

    def find_perfect(
      perfect_intervals : Array(PerfectInterval),
      window : Array(Int32), threshold : Int32,
      start : Int32, win_len : Int32, repeat_value : Int32,
      curr_value : Array(Int32)
    )
      max_repeat = 0
      max_length = 0

      c = curr_value.clone
      (window.size - win_len - 1).downto(0) do |i|
        t = window[i]
        repeat_value += c[t]; c[t] += 1
        new_repeat = repeat_value
        new_length = window.size - i - 1

        if new_repeat * 10 > threshold * new_length
          j = 0
          while j < perfect_intervals.size && perfect_intervals[j].start >= i + start
            pi = perfect_intervals[j]
            if max_repeat == 0 || pi.repeat * max_length > max_repeat * pi.length
              max_repeat = pi.repeat
              max_length = pi.length
            end
            j += 1
          end

          if (max_repeat == 0 || new_repeat * max_length >= max_repeat * new_length)
            max_repeat = new_repeat
            max_length = new_length

            perfect_intervals.insert(j, PerfectInterval.new(i + start, window.size + WordLength - 1 + start, new_repeat, new_length))
          end
        end
      end
    end
  end
end
