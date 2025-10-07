<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>池田大介 | ITエンジニア</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="24年の実務経験 × プログラミング技術で価値を創造。業務効率化・アプリ開発・データ処理で実務課題を解決します。">
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <div class="container">
    <!-- Header -->
    <div class="profile-header">
      <div class="header-content">
        <img class="avatar" src="image/github_avatar_icon.png" alt="池田大介">
        <div class="header-text">
          <h1 class="name">池田 大介 (Daisuke Ikeda)</h1>
          <p class="title">ITエンジニア志望</p>
          <p class="meta">公共職業訓練受講中（2025年6月～12月）</p>
          <p class="status">🟢 転職活動中</p>
        </div>
      </div>
      <div class="focus-areas">
        <span class="focus-tag">⚡ 業務効率化</span>
        <span class="focus-tag">💻 アプリ開発</span>
        <span class="focus-tag">🔄 業務自動化</span>
      </div>
    </div>

    <!-- About Me -->
    <div class="section">
      <h2 class="section-title">👋 About Me</h2>
      <p class="bio-text">
        <span class="highlight">24年間にわたり測量業・営業・自営業など多様な業界で実務経験を積み</span>、
        現在は公共職業訓練にてプログラミング技術を習得中です。
      </p>
      <p class="bio-text">
        <span class="highlight">測量業務8年の経験</span>で培った問題発見力と、
        プログラミングスキルを組み合わせ、実務の課題を技術で解決することに取り組んでいます。
        業務全体を見渡した自動化システムの設計・開発が強みです。
      </p>
    </div>

    <!-- Main Project -->
    <div class="section">
      <h2 class="section-title">🚀 Featured Project</h2>
      
      <!-- Integrated System -->
      <div class="project-card main-project">
        <h3 class="project-title">📊 測量報告書作成自動化システム</h3>
        
        <div class="project-tags">
          <span class="project-tag">Python</span>
          <span class="project-tag">機械学習</span>
          <span class="project-tag">Excel VBA</span>
          <span class="project-tag">業務自動化</span>
        </div>

        <div class="project-section">
          <h4 class="project-subtitle">解決した課題</h4>
          <p class="project-text">
            測量業務において、以下の課題がありました：
          </p>
          <ul class="project-list">
            <li>写真内容（遠景/近景など）を目視で判別する必要がある</li>
            <li>報告書に写真を1枚ずつ手作業で配置する必要がある</li>
            <li>測量画像の管理が煩雑で時間がかかる</li>
          </ul>
          <p class="project-text">
            この作業は1件あたり<span class="highlight">数時間かかっていました</span>。
            年間40〜80件の業務で大きな負担となっていたため、
            <span class="highlight">3つのサブシステムを連携させた完全自動化システム</span>を開発しました。
          </p>
        </div>

        <!-- 開発手法を追加 -->
        <div class="dev-approach-card">
          <h4 class="approach-title">💡 開発プロセス</h4>
          <ul class="approach-list">
            <li><strong>実務経験からの課題抽出：</strong>8年間の測量業務で実際に直面した課題を分析し、システム要件を定義</li>
            <li><strong>生成AI（Claude/ChatGPT）の活用：</strong>要件定義をもとに、生成AIを使って効率的にコード生成</li>
            <li><strong>コードレビューと学習：</strong>生成されたコードを読解・カスタマイズしながら、仕組みを理解</li>
            <li><strong>技術書による理論補完：</strong>オライリー技術書で基礎理論を学び、実装の裏付けを強化</li>
          </ul>
        </div>

        <div class="project-section">
          <h4 class="project-subtitle">システム構成</h4>
          <p class="project-text">業務フローに沿った3段階の自動化を実現：</p>
        </div>

        <div class="subsystem-card">
          <h4 class="subsystem-title">ステップ1: GPSSCAN（写真リネーム自動化）</h4>
          <p class="subsystem-desc">
            SIMファイル（測量データ）とGPS情報から、写真を測量点に自動マッチング。
            体系的なファイル名に一括リネーム。
          </p>
          <div class="subsystem-features">
            <strong>主な機能：</strong>
            <ul class="feature-list">
              <li>SIMファイル解析（A01/A02/D00形式対応）</li>
              <li>GPS座標の自動平面直角座標変換（EPSG:6669-6687）</li>
              <li>ドラッグ&ドロップによる直感的なマッチングUI</li>
              <li>測量点・地番境界の地図可視化</li>
            </ul>
            <div class="tech-stack-inline">
              <span class="tech-badge-sm">Python</span>
              <span class="tech-badge-sm">Tkinter</span>
              <span class="tech-badge-sm">Matplotlib</span>
              <span class="tech-badge-sm">pyproj</span>
              <span class="tech-badge-sm">pandas</span>
            </div>
          </div>
          <div class="github-link-section">
            <a href="https://github.com/D1424-da/GPSSCAN" target="_blank" class="github-repo-link-sm">
              <span class="link-icon">💻</span> GitHubでコードを見る
            </a>
          </div>
        </div>

        <div class="subsystem-card">
          <h4 class="subsystem-title">ステップ2: AI画像認識（写真分類自動化）</h4>
          <p class="subsystem-desc">
            機械学習により、写真の内容を自動判別。遠景/近景などを自動分類し、
            次のステップに必要な情報を付与。
          </p>
          <div class="subsystem-features">
            <strong>技術的な取り組み：</strong>
            <ul class="feature-list">
              <li>192,000枚の画像データセット作成（12クラス × 各16,000枚）</li>
              <li>TensorFlow/Kerasによるディープラーニングモデル構築</li>
              <li>データ拡張による汎化性能向上</li>
            </ul>
            <div class="tech-stack-inline">
              <span class="tech-badge-sm">Python</span>
              <span class="tech-badge-sm">TensorFlow/Keras</span>
              <span class="tech-badge-sm">OpenCV</span>
              <span class="tech-badge-sm">scikit-learn</span>
            </div>
          </div>
          <div class="github-link-section">
            <a href="https://github.com/D1424-da/AI" target="_blank" class="github-repo-link-sm">
              <span class="link-icon">💻</span> GitHubでコードを見る
            </a>
          </div>
        </div>

        <div class="subsystem-card">
          <h4 class="subsystem-title">ステップ3: 自動写真アルバム（報告書配置自動化）</h4>
          <p class="subsystem-desc">
            Excel VBAにより、整理された写真を報告書フォーマットに自動配置。
            最終的な測量報告書を完成。
          </p>
          <div class="subsystem-features">
            <strong>実装内容：</strong>
            <ul class="feature-list">
              <li>測量点ごとに写真を自動配置</li>
              <li>遠景/近景の配置位置を自動判定</li>
              <li>報告書フォーマットに準拠した体裁調整</li>
            </ul>
            <div class="tech-stack-inline">
              <span class="tech-badge-sm">Excel VBA</span>
              <span class="tech-badge-sm">マクロ自動化</span>
            </div>
          </div>
        </div>

        <div class="project-section results-section">
          <h4 class="project-subtitle">成果</h4>
          <div class="results-grid">
            <div class="result-item">
              <div class="result-number">数時間 → 数分</div>
              <div class="result-label">作業時間の劇的短縮</div>
            </div>
            <div class="result-item">
              <div class="result-number">年間40〜80件</div>
              <div class="result-label">適用業務数</div>
            </div>
            <div class="result-item">
              <div class="result-number">3システム連携</div>
              <div class="result-label">統合ワークフロー</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Other Projects -->
    <div class="section">
      <h2 class="section-title">💼 Other Projects</h2>
      
      <div class="project-card-simple">
        <h3 class="project-title-simple">📁 高速ファイル検索アプリ</h3>
        <p class="project-desc-simple">
          測量資料を紙ベースで保管していたため、保管場所と書類管理が大変という課題を解決。
          デジタル化した資料を高速検索できるツールを開発し、必要な書類をすぐに見つけられるようにしました。
        </p>
        <div class="tech-stack-inline">
          <span class="tech-badge-sm">Python</span>
          <span class="tech-badge-sm">Tkinter</span>
        </div>
        <div class="github-link-section">
          <a href="https://github.com/D1424-da/file-search-app" target="_blank" class="github-repo-link-sm">
            <span class="link-icon">💻</span> GitHubでコードを見る
          </a>
        </div>
      </div>
    </div>

    <!-- Tech Stack -->
    <div class="section">
      <h2 class="section-title">💻 Tech Stack</h2>
      
      <h3 class="subsection-title">言語</h3>
      <div class="tech-stack">
        <span class="tech-badge">Python</span>
        <span class="tech-badge">Excel VBA</span>
        <span class="tech-badge">JavaScript</span>
        <span class="tech-badge">PHP</span>
        <span class="tech-badge">C#</span>
        <span class="tech-badge">SQL</span>
        <span class="tech-badge">HTML/CSS</span>
      </div>

      <h3 class="subsection-title">フレームワーク・ライブラリ</h3>
      <div class="tech-stack">
        <span class="tech-badge tech-fw">Tkinter (GUI)</span>
        <span class="tech-badge tech-fw">pandas (データ処理)</span>
        <span class="tech-badge tech-fw">NumPy</span>
        <span class="tech-badge tech-fw">Matplotlib (可視化)</span>
        <span class="tech-badge tech-fw">OpenCV (画像処理)</span>
        <span class="tech-badge tech-fw">TensorFlow/Keras (機械学習)</span>
        <span class="tech-badge tech-fw">scikit-learn</span>
      </div>

      <h3 class="subsection-title">その他</h3>
      <div class="tech-stack">
        <span class="tech-badge tech-other">Git</span>
        <span class="tech-badge tech-other">CAD</span>
        <span class="tech-badge tech-other">生成AI（Claude/ChatGPT）</span>
        <span class="tech-badge tech-other">デジタルマーケティング</span>
      </div>
    </div>

    <!-- Learning -->
    <div class="section">
      <h2 class="section-title">📚 継続的な学習</h2>
      
      <p class="learning-summary">
        オライリー技術書を中心に、理論と実践を両立させた学習を継続中。
        <span class="highlight">生成AI（Claude/ChatGPT）で作成したコードを読解しながら、技術書で理論を補完</span>することで、
        実務で使える技術習得を目指しています。
      </p>

      <div class="learning-books">
        <h3 class="book-category">学習アプローチ</h3>
        <ul class="book-simple-list">
          <li><strong>生成AIの活用：</strong>実務課題の解決に必要なコードを効率的に生成</li>
          <li><strong>コードレビュー：</strong>生成されたコードの仕組みを理解し、カスタマイズ</li>
          <li><strong>理論学習：</strong>オライリー技術書で基礎理論を体系的に学習</li>
          <li><strong>実践と検証：</strong>学んだ知識を即座にプロジェクトで実装</li>
        </ul>
      </div>

      <div class="learning-books" style="margin-top: 20px;">
        <h3 class="book-category">現在学習中の主要書籍</h3>
        <ul class="book-simple-list">
          <li>入門 Python 3（オライリー）</li>
          <li>Pythonではじめる機械学習（オライリー）</li>
          <li>退屈なことはPythonにやらせよう（オライリー）</li>
          <li>ゼロから作るDeep Learning（オライリー）</li>
        </ul>
      </div>
    </div>

    <!-- Work Experience -->
    <div class="section">
      <h2 class="section-title">💼 Work Experience</h2>
      <div class="experience-list">
        <div class="experience-item">
          <div class="experience-header">
            <div class="experience-title">測量業務担当 - 土地家屋調査士事務所</div>
            <div class="experience-period">2017年4月～2025年6月（8年3ヶ月）</div>
          </div>
          <p class="experience-desc">
            年間40～80件の土地境界確定・登記業務を担当。
            <span class="highlight">業務フロー全体を理解し、自動化システムの設計・開発</span>に活かしました。
          </p>
        </div>

        <div class="experience-item">
          <div class="experience-header">
            <div class="experience-title">経営統括 - 仕出し・惣菜販売業</div>
            <div class="experience-period">2013年6月～2016年10月（3年5ヶ月）</div>
          </div>
          <p class="experience-desc">
            <span class="highlight">SNS集客で月間60件の新規顧客獲得</span>を実現。
            デジタルマーケティングの実践経験を積みました。
          </p>
        </div>

        <div class="experience-item">
          <div class="experience-header">
            <div class="experience-title">経営者 - 古着リサイクルショップ（自営）</div>
            <div class="experience-period">2010年4月～2013年4月（3年間）</div>
          </div>
          <p class="experience-desc">
            オンライン販売戦略を企画・実行。
            <span class="highlight">Webページ制作の基礎技術を習得</span>しました。
          </p>
        </div>

        <div class="experience-item">
          <div class="experience-header">
            <div class="experience-title">店舗責任者 - 総合リサイクルショップ</div>
            <div class="experience-period">2006年6月～2010年2月（3年8ヶ月）</div>
          </div>
          <p class="experience-desc">
            <span class="highlight">グループ9店舗中、売上伸び率1位</span>を達成。
            チームマネジメントとリーダーシップを身につけました。
          </p>
        </div>
      </div>
    </div>

    <!-- Certifications -->
    <div class="section">
      <h2 class="section-title">🎓 保有資格</h2>
      <div class="qualifications">
        <div class="qualification-item">
          <div class="qualification-icon">📐</div>
          <div class="qualification-info">
            <div class="qualification-name">測量士補</div>
            <div class="qualification-date">2021年1月取得</div>
          </div>
        </div>
        <div class="qualification-item">
          <div class="qualification-icon">🚗</div>
          <div class="qualification-info">
            <div class="qualification-name">普通自動車第一種運転免許</div>
            <div class="qualification-date">2001年6月取得</div>
          </div>
        </div>
        <div class="qualification-item">
          <div class="qualification-icon">🏍️</div>
          <div class="qualification-info">
            <div class="qualification-name">普通自動二輪運転免許</div>
            <div class="qualification-date">2001年6月取得</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Contact -->
    <div class="section">
      <h2 class="section-title">📫 Contact</h2>
      <p class="contact-text">
        現在、業務効率化・アプリ開発・システム自動化分野での転職活動中です。<br>
        お気軽にご連絡ください。
      </p>
      <div class="contact-links">
        <a href="https://github.com/D1424-da" target="_blank" class="contact-link github">
          <span class="link-icon">💻</span> GitHub
        </a>
        <a href="mailto:d.i.a.0101@gmail.com" class="contact-link email">
          <span class="link-icon">✉️</span> Email
        </a>
      </div>
    </div>

    <footer class="footer">
      <p>© 2025 Daisuke Ikeda. 24年の実務経験 × プログラミング技術で価値を創造します。</p>
    </footer>
  </div>
</body>
</html>
