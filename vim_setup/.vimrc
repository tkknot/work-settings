" vim設定ファイル

" vscodeの設定と紐づけるときの当ファイル配置パス
" ＄HOME/.vimrc

" =======================================================================
" 汎用設定
" =======================================================================

" 文字コードをUTF-8に設定
set encoding=utf-8
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" 入力中のコマンドをステータスに表示する
set showcmd

" 行番号を表示
set number
" 現在の行を強調表示
set cursorline
" 現在の行番号を相対表示
set relativenumber
" 現在の行を強調表示（縦）
" set cursorcolumn
" 行末の1文字先までカーソルを移動できるように
set virtualedit=onemore
" インデントはスマートインデント
set smartindent
" ビープ音を可視化
set visualbell
" 括弧入力時の対応する括弧を表示
set showmatch
" ステータスラインを常に表示
set laststatus=2
" コマンドラインの補完
set wildmode=list:longest
" 折り返し時に表示行単位での移動できるようにする
nnoremap j gj
nnoremap k gk
" シンタックスハイライトの有効化
syntax on

" 不可視文字を可視化(タブが「▸-」と表示される)
set list listchars=tab:\▸\-
" Tab文字を半角スペースにする
set expandtab
" 行頭以外のTab文字の表示幅（スペースいくつ分）
set tabstop=2
" 行頭でのTab文字の表示幅
set shiftwidth=2
" 新しい行のインデントを同じレベルにしてくれる
set autoindent

" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
" set smartcase
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索語をハイライト表示
set hlsearch
" ESC連打でハイライト解除
" nmap <Esc><Esc> :nohlsearch<CR><Esc>

" :terでターミナルのウィンドウが下に15行開く
set splitbelow
set termwinsize=15x0

" 最下ウィンドウにステータス行を表示
set laststatus=2

" コピペ設定
set clipboard=unnamed,autoselect

" VS Code のコメント アクションをシミュレートする
nmap <space>c :call ToggleComment()<CR>

" コメントのトグル関数
function! ToggleComment()
    let linewise = &selection == 'lines'
    let inclusive = &selection == 'inclusive'

    if linewise
        normal! ggVGy
    endif

    silent execute 'normal! g<c-g>ip' . "\<esc>"

    if linewise
        silent! normal! V
    endif

    silent! execute 'normal! gq'

    if linewise
        silent! normal! g<c-g>u<c-u>
    endif
endfunction

" =======================================================================
" ノーマルモード
" =======================================================================

" 左右分割
nnoremap <space>v :vsplit<CR>
" 上下分割
nnoremap <space>s :split<CR>

" バッファ（開いているファイル）の切り替え
nnoremap <space>h :bprevious<CR>
nnoremap <space>l :bnext<CR>

" ホームポジションから手を離さずに末端へのカーソル移動
noremap <S-h> ^
noremap <S-j> }
noremap <S-k> {
noremap <S-l> $

" 編集終了
nnoremap <space>w :w!<CR>
nnoremap <space>q :q!<CR>
nnoremap <space>x :x!<CR>

" vimrcをスペースドットで開く
nnoremap <space>. :<c-u>tabedit $MYVIMRC<CR>

" =======================================================================
" 入力モード
" =======================================================================

" 入力時に、すぐにノーマルに戻る 
inoremap jj <Esc>
