# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'json'

enable :sessions

ERROR_MESSAGE_DELETED_MEMO = '既に削除されたメモです。'
ERROR_MESSAGE_EMPTY_MEMO = 'タイトル、内容にはテキストを入力してください。'
class Memo
  attr_accessor :id, :title, :content

  def initialize(id, title, content)
    @id = id
    @title = title
    @content = content
  end

  def self.all
    memo_hash_objects = []
    File.open('data.json') do |f|
      memo_hash_objects = JSON.parse(f.read)['memos']
    end
    memo_hash_objects.map do |memo_hash_object|
      Memo.new(memo_hash_object['id'], memo_hash_object['title'], memo_hash_object['content'])
    end
  end

  def self.find_by_id(id)
    all.find { |memo| memo.id == id }
  end

  def create
    Memo.write(Memo.all.push(self).map(&:hash))
  end

  def delete
    memos = Memo.all.delete_if { |memo| memo.id == @id.to_i }
    Memo.write(memos.map(&:hash))
  end

  def save
    edited_memos = Memo.all.map do |memo|
      memo.id == @id ? self : memo
    end
    Memo.write(edited_memos.map(&:hash))
  end

  def hash
    {
      "id": @id,
      "title": @title,
      "content": @content
    }
  end

  def self.write(memo_hash_objects)
    File.open('data.json', 'w') do |f|
      JSON.dump({ 'memos' => memo_hash_objects }, f)
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

get '/memos/new' do
  erb :new
end

get '/memos/edit/:id' do
  @memo = Memo.find_by_id(params['id'].to_i)
  erb :edit
end

get '/memos/:id' do
  @memo = Memo.find_by_id(params['id'].to_i)
  erb :detail
end

post '/memos' do
  if params['title'].strip.empty? || params['content'].strip.empty?
    show_error_message(ERROR_MESSAGE_EMPTY_MEMO)
    redirect '/memos/new'
    return
  end

  new_id = Memo.all.empty? ? 0 : Memo.all.map(&:id).max + 1
  memo = Memo.new(new_id, escape_html(params['title']), escape_html(params['content']))
  memo.create
  redirect '/memos'
  erb :index
end

patch '/memos/:id' do
  target_memo = Memo.find_by_id(params['id'].to_i)
  unless target_memo
    show_error_message(ERROR_MESSAGE_DELETED_MEMO)
    redirect '/memos'
    return
  end

  if params['title'].strip.empty? || params['content'].strip.empty?
    show_error_message(ERROR_MESSAGE_EMPTY_MEMO)
    redirect "/memos/#{params['id']}"
    return
  end

  target_memo.title = escape_html(params['title'])
  target_memo.content = escape_html(params['content'])
  target_memo.save
  redirect '/memos'
  erb :index
end

delete '/memos/:id' do
  target_memo = Memo.find_by_id(params['id'].to_i)
  unless target_memo
    show_error_message(ERROR_MESSAGE_DELETED_MEMO)
    redirect '/memos'
    return
  end

  target_memo.delete
  redirect '/memos'
  erb :index
end

def show_error_message(message)
  flash[:error] = message
end
