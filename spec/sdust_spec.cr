require "./spec_helper"

def run_sdust(input_file : String, t : Int32, expected_output_file : String, threads : Int32 = 1)
  io = IO::Memory.new
  Sdust::App.new(input_file, 20, t, threads).run(io)
  correct_result = File.read(expected_output_file)
  io.to_s.should eq correct_result
end

describe Sdust do
  it "has a version number" do
    Sdust::VERSION.should_not be_nil
  end

  it "run moo.fa with t=8" do
    run_sdust("#{__DIR__}/fixtures/moo.fa", 8, "#{__DIR__}/fixtures/moo_t08.txt")
  end

  it "run moo.fa with t=10" do
    run_sdust("#{__DIR__}/fixtures/moo.fa", 10, "#{__DIR__}/fixtures/moo_t10.txt")
  end

  it "run moo.fa.gz with t=8" do
    run_sdust("#{__DIR__}/fixtures/moo.fa.gz", 8, "#{__DIR__}/fixtures/moo_t08.txt")
  end

  it "run moo.fa.gz with t=10" do
    run_sdust("#{__DIR__}/fixtures/moo.fa.gz", 10, "#{__DIR__}/fixtures/moo_t10.txt")
  end

  {% if flag?(:execution_context) && flag?(:preview_mt) %}
    it "run moo.fa with t=8 using two workers" do
      run_sdust("#{__DIR__}/fixtures/moo.fa", 8, "#{__DIR__}/fixtures/moo_t08.txt", threads: 2)
    end

    it "run moo.fa with t=8 using all workers" do
      run_sdust("#{__DIR__}/fixtures/moo.fa", 8, "#{__DIR__}/fixtures/moo_t08.txt", threads: 0)
    end
  {% end %}
end
