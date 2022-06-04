# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'json'

enable :sessions
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

  def self.find_by_id(id)
    all.find { |memo| memo.id == id }
  end

  def add
    Memo.write(Memo.all.push(self).map(&:hash))
  end

  def delete
    memos = Memo.all.delete_if { |memo| memo.id == id.to_i }
    Memo.write(memos.map(&:hash))
  end

  def edit
    edited_memos = Memo.all.map do |memo|
      memo.id == id ? self : memo
    end
    Memo.write(edited_memos.map(&:hash))
  end

  def hash
    {
      "id": id,
      "title": title,
      "content": content
    }
  end

  def self.write(hash_memos)
    File.open('data.json', 'w') do |file|
      JSON.dump({ 'memos' => hash_memos }, file)
    end
  end
end

helpers do
  include Rack::Utils
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
  @memo = Memo.find_by_id(params['id'].to_i)
  erb :edit
end

get '/:id' do
  @memo = Memo.find_by_id(params['id'].to_i)
  erb :detail
end

post '/memos' do
  if params['title'].strip.empty? || params['content'].strip.empty?
    flash[:alert] = 'タイトル、内容にはテキストを入力してください。'
    redirect '/new'
  else
    new_id = Memo.all.empty? ? 0 : Memo.all.map(&:id).max + 1
    memo = Memo.new(new_id, escape_html(params['title']), escape_html(params['content']))
    memo.add
    redirect '/memos'
    erb :index
  end
end

post '/memos/edit/:id' do
  edited_memo = Memo.find_by_id(params['id'].to_i)
  if edited_memo
    edited_memo.title = escape_html(params['title'])
    edited_memo.content = escape_html(params['content'])
    edited_memo.edit
    redirect '/memos'
    erb :index
  else
    flash[:error] = '既に削除されたメモです。'
    redirect '/memos'
  end
end

post '/memos/delete/:id' do
  deleted_memo = Memo.find_by_id(params['id'].to_i)
  if deleted_memo
    deleted_memo.delete
    redirect '/memos'
    erb :index
  else
    flash[:error] = '既に削除されたメモです。'
    redirect '/memos'
  end
end
