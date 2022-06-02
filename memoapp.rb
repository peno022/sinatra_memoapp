# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'

class Memo
  attr_accessor :id, :title, :content

  def initialize(id, title, content)
    @id = id
    @title = title
    @content = content
  end

  def self.all
    memos_hash = ''
    File.open('data.json') do |file|
      memos_hash = JSON.parse(file.read)['memos']
    end
    memos = []
    memos_hash.each do |memo_hash|
      memos.push(Memo.new(memo_hash['id'], memo_hash['title'], memo_hash['content']))
    end
    memos
  end

  def self.add(new_memo)
    write(hash_memos(all.push(new_memo)))
  end

  def self.delete(delete_memo_id)
    memos = all.delete_if { |memo| memo.id == delete_memo_id.to_i }
    write(hash_memos(memos))
  end

  def self.edit(edited_memo)
    edited_memos = all.each do |memo|
      if memo.id == edited_memo.id
        memo.title = edited_memo.title
        memo.content = edited_memo.content
      end
    end
    write(hash_memos(edited_memos))
  end

  def self.hash_memos(memos)
    memos.map do |memo|
      {
        "id": memo.id,
        "title": memo.title,
        "content": memo.content
      }
    end
  end

  def self.write(hash_memos)
    File.open('data.json', 'w') do |file|
      JSON.dump({ 'memos' => hash_memos }, file)
    end
  end
end

get '/' do
  redirect '/memos'
  erb :index
end

get '/memos' do
  @memos = Memo.all
  erb :index
end

get '/new' do
  erb :new
end

get '/memos/edit/:id' do
  @memo = Memo.all.find { |memo| memo.id == params['id'].to_i }
  erb :edit
end

get '/:id' do
  @memo = Memo.all.find { |memo| memo.id == params['id'].to_i }
  erb :detail
end

post '/memos' do
  memo = Memo.new(Memo.all.length + 1, params['title'], params['content'])
  Memo.add(memo)
  redirect '/memos'
  erb :index
end

post '/memos/edit/:id' do
  edited_memo = Memo.all.find { |memo| memo.id == params['id'].to_i }
  edited_memo.title = params['title']
  edited_memo.content = params['content']
  # ファイル書き込み
  Memo.edit(edited_memo)
  redirect '/memos'
  erb :index
end

post '/memos/delete/:id' do
  Memo.delete(params['id'])
  redirect '/memos'
  erb :index
end
