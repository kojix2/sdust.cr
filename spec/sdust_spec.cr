require "./spec_helper"

describe Sdust do
  it "has a version number" do
    Sdust::VERSION.should_not be_nil
  end

  it "run moo.fa with t=8" do
    io = IO::Memory.new
    Sdust::App.new("#{__DIR__}/fixtures/moo.fa", 20, 9).run(io)
    correct_result_t08 = File.read("#{__DIR__}/fixtures/moo_t08.txt")
    io.to_s.should eq correct_result_t08
  end

  it "run moo.fa with t=10" do
    io = IO::Memory.new
    Sdust::App.new("#{__DIR__}/fixtures/moo.fa", 20, 10).run(io)
    correct_result_t08 = File.read("#{__DIR__}/fixtures/moo_t10.txt")
    io.to_s.should eq correct_result_t08
  end
end
