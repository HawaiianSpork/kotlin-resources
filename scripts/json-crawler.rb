class Crawl

  #CONSTANT = ""
  #@@variable = ""
  require 'open-uri'
  require 'uri'
  require 'nokogiri'
  require 'HTTParty'
  require 'rubygems'
  require 'json'
  require 'pp'
  require 'mini_magick'

  HR                      = "----------------------------"


  def initialize
    @COUNTER                  = 0
    @jsonArray                = []
    @libraries                = []
    @listOfLicences           = ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'License', 'License.md', 'license', 'license.md']
    @listOfReadmes            = ['README.md', 'readme.md', 'Readme.md', 'ReadMe.md']
    @jsonFileName             = ''
    @json                     = ''
    @category                 = ''
    @websiteUrl               = ''
    @website                  = ''
    @document                 = ''
    @readmeRawUrl             = ''
    @file                     = ''
    @contents                 = ''
    @projectPlatform          = ''
    @projectName              = ''
    @projectDescription       = ''
    @projectCategory          = ''
    @projectTag               = ''
    @projectUrl               = ''
    @projectVersion           = ''
    @projectLicense           = ''
    @projectMavenGroupId      = ''
    @projectMavenArtifactId   = ''
    @projectMavenVersion      = ''
    @projectCreatorName       = ''
    @projectCreatorEmail      = ''
    @projectCreatorTwitter    = ''
    @projectImage             = ''
    @projectYoutubeId         = ''
  end

  def clear
    system("clear")
  end

  def hr
    puts HR
  end

  def collectJSON
    @jsonFiles = Dir.pwd + '/../resources/**/*.json'
    Dir.glob(@jsonFiles) do |file|
      @jsonArray << file
    end
    return @jsonArray
  end

  def getDescription(projectUrl)
    @website = HTTParty.get(projectUrl)
    @document = Nokogiri::HTML(@website)
  end

  def addDescription(projectUrl)
    getDescription(projectUrl)

    if @document.css('div.repository-meta-content span')[0]
      @tempDescription = @document.css('div.repository-meta-content span')[0].text.sub( ':', ' -' ).strip
    else
      @tempDescription =""
    end

    if @tempDescription.empty? || @tempDescription.nil?
      puts 'Description: ' + "\033[31m" + "Empty?" + "\033[0m\n"
    else
      puts 'Description: ' + "\033[32m" +  ( @tempDescription ) + " \033[0m\n"
    end

    return @tempDescription
  end

  def fixRelativePath( str )
    @tempUrl = 'https://github.com/' + @projectCreatorName + '/' + @projectName + '/tree/master/'
    str.gsub %r{\[([^\]]+)\]\(((?!http|www\.|\#|\.com|\.net|\.info|\.org).*?)\)}x, '[\1]('+ @tempUrl + '\2)'
  end

  def fixImgRealtiveSrc( str )
    @tempImgSrc = 'https://raw.githubusercontent.com/' + @projectCreatorName + '/' + @projectName + '/master/'
    str.gsub %r{src=[\"']((?!http|https).*?)[\"'].*?}x, 'src="' + @tempImgSrc + '\1"'
  end

  def fixImgMissingAlt( str )
    @tempImgAlt = @projectName + ' by ' + @projectCreatorName
    str.gsub %r{<(img(?!.*?alt=(['"]).*?\2)[^>]*).\/>}x, '<\1' + ' alt="' + @tempImgAlt + '" />'
  end

  def addGithubReadMe
    @tryReadmeRawUrlIsValid = ""
    @listOfReadmes.each do |valid|
      @readmeRawUrl = 'https://raw.githubusercontent.com/' + @projectCreatorName + '/' + @projectName + '/master/' + valid
      @readmeWeb = HTTParty.get(@readmeRawUrl)
      case @readmeWeb.code
        when 200
          if @file = open(@readmeRawUrl)
            @contents << @file.read
            @contents = fixImgMissingAlt(@contents)
            @contents = fixImgRealtiveSrc(@contents)
            @contents = fixRelativePath(@contents)
            puts 'GithubReadMe: ' + "\033[32m" +  'Added' + " \033[0m\n"
          else
            puts "\033[31m" + "Error" + "\033[0m\n"
          end
        when 404
          # puts "do nothing"
        when 500...600
          # @tryLicenseRawUrlIsValid = "ZOMG ERROR #{response.code}"
      end
    end
  end

  def addGithubLicense
    @tryLicenseRawUrlIsValid = ""
    @listOfLicences.each do |valid|
      @tryLicenseRawUrl = 'https://raw.githubusercontent.com/' + @projectCreatorName + '/' + @projectName + '/master/' + valid
      @licenseWeb = HTTParty.get(@tryLicenseRawUrl)
      case @licenseWeb.code
        when 200
          @tryLicenseRawUrlIsValid = valid
        when 404
          # do nothing
        when 500...600
          # @tryLicenseRawUrlIsValid = "ZOMG ERROR #{response.code}"
      end
    end
    if @tryLicenseRawUrlIsValid.empty?
      puts 'Valid Lincense url: ' + "\033[31m" + "Not found" + "\033[0m\n"
    else
      puts "Valid Lincense url: " + "\033[32m" + @tryLicenseRawUrlIsValid + " \033[0m\n"
    end
    return @tryLicenseRawUrl
  end

  def xmlJitpack(url)
    @doc = Nokogiri::XML(open(url))
     puts "Maven: " + "\033[32m" + "jitpack"  + " \033[0m\n"
    @maven      =   []
    @maven      <<  @doc.xpath('//groupId').text
    @maven      <<  @doc.xpath('//artifactId').text
    @maven      <<  @doc.xpath('//release').text
    return @maven
  end

  def xmlBintray(url)
    @doc = Nokogiri::XML(open(url))
     puts "Maven: " + "\033[32m" + "bintray"  + " \033[0m\n"
    @maven      =   []
    @maven      <<  @doc.xpath('//groupId').text
    @maven      <<  @doc.xpath('//artifactId').text
    @maven      <<  @doc.xpath('//latest').text
    return @maven
  end

  def xmlMaven(url)
    @doc = Nokogiri::XML(open(url))
    puts "Maven: " + "\033[32m" + "maven"  + " \033[0m\n"
    @maven      =   []
    @maven      <<  @doc.xpath('//groupId').text
    @maven      <<  @doc.xpath('//artifactId').text
    @maven      <<  @doc.xpath('//latest').text
    return @maven
  end

  def xmlJetbrains(url)
    @doc = Nokogiri::XML(open(url))
    puts "Maven: " + "\033[32m" + "jetbrains"  + " \033[0m\n"
    @maven      =   []
    @maven      <<  @doc.xpath('//groupId').text
    @maven      <<  @doc.xpath('//artifactId').text
    @maven      <<  @doc.xpath('//latest').text
    return @maven
  end

  def xmlSonatype(url)
    @doc = Nokogiri::XML(open(url))
    puts "Maven: " + "\033[32m" + "sonatype"  + " \033[0m\n"
    @maven      =   []
    @maven      <<  @doc.xpath('//groupId').text
    @maven      <<  @doc.xpath('//artifactId').text
    @maven      <<  @doc.xpath('//latest').text
    return @maven
  end

  def xmlEmpty(url)
    puts "Maven: " "\033[31m" + "NA" + "\033[0m\n"
    @maven      =   []
    @maven      <<  " "
    @maven      <<  " "
    @maven      <<  " "
    return @maven
  end

  def xmlParse(url)
    @xmlType = url
    if @xmlType.match(/\bjitpack\b/)
      xmlJitpack(url)
    elsif @xmlType.match(/\bbintray\b/)
      xmlBintray(url)
    elsif @xmlType.match(/\bmaven\b/)
      xmlMaven(url)
    elsif @xmlType.match(/\bjetbrains\b/)
      xmlJetbrains(url)
    else @xmlType.empty?
      xmlEmpty(url)
    end
  end

  def createFolder(dirname)
    dirname.prepend('../_posts/libraries/')
    unless Dir.exists?(dirname)
      Dir.mkdir(dirname)
      puts 'Folder created: ' + "\033[32m" +  ( dirname ) + " \033[0m\n"
    end
  end

  def setFileName
    @d = DateTime.now
    @prefix = @d.strftime("%Y-%m-%d")
    @filename = @prefix + '-' + @projectName  + '.md'
  end

  def saveFile
    @rootDir = Dir.pwd
    Dir.chdir(@dirname)
    @output = File.open( @filename,"w" )
    @output << @contents
    @output.close
    Dir.chdir(@rootDir)
    return true
  end

  def success
    puts 'File successfully created: ' + "\033[32m" + @filename + " \033[0m\n"
    hr
  end

  def shareImgGenerate(projectName, projectDescription)
    MiniMagick::Tool::Convert.new do |convert|
      convert << "../assets/kotlin-resources-grad-v1.png"
      convert.size "800x200"
      convert.background "Transparent"
      convert.gravity "Center"
      convert.fill "#ffffff"
      convert.font "../assets/Hind/Hind-Medium.ttf"
      convert.caption "#{projectDescription}"
      convert.geometry "+0+100"
      convert.antialias
      convert.composite
      convert.size "1000x300"
      convert.background "Transparent"
      convert.gravity "Center"
      convert.fill "#ffffff"
      convert.font "../assets/Hind/Hind-Bold.ttf"
      convert.caption "#{projectName}"
      convert.geometry "+0-80"
      convert.antialias
      convert.composite
      convert << "../assets/img/libraries/#{projectName}.jpg"
    end
    puts "Image generated: " + "\033[32m" + "../assets/img/libraries/#{projectName}.jpg" + " \033[0m\n"
  end

  def parseJSON
    clear
    collectJSON

    @jsonArray.each do |url|

      @json = File.read(url)
      @library = JSON.parse(@json)

      @COUNTER +=1
      puts @COUNTER.to_s + '/' + @jsonArray.length.to_s
      puts "Library: " + "\033[32m" + @library["name"] + " \033[0m\n"

      begin
        xmlParse(@library["mavenMetaUrl"])

        @contents = '---'                                                                                                       + "\n"
        @contents << 'layout: '          +    'post'                                                                            + "\n"
        @contents << 'platform: '        +    ( @projectPlatform          = @library["platform"]                              ) + "\n"
        @contents << 'title: '           +    ( @projectName              = @library["name"].split('/')[1]                    ) + "\n"
        @contents << 'description: '     +    ( @projectDescription       = addDescription(@library["sourceUrl"])             ) + "\n"
        @contents << 'category: '        +    ( @projectCategory          = @library["category"]                              ) + "\n"
        @contents << 'tags: '            +    ( @projectTag               = @library["tags"].to_s                             ) + "\n"
        @contents << 'sourceUrl: '       +    ( @projectUrl               = @library["sourceUrl"]                             ) + "\n"
        @contents << 'maven: '                                                                                                  + "\n"
        @contents << '  groupId: '       +    ( @projectMavenGroupId      = @maven[0]                                         ) + "\n"
        @contents << '  artifactId: '    +    ( @projectMavenArtifactId   = @maven[1]                                         ) + "\n"
        @contents << '  version: '       +    ( @projectMavenVersion      = @maven[2]                                         ) + "\n"
        @contents << 'creator: '                                                                                                + "\n"
        @contents << '  name: '          +    ( @projectCreatorName       = @library["name"].split('/')[0]                    ) + "\n"
        @contents << '  email: '         +    ( @projectCreatorEmail      = ''                                                ) + "\n"
        @contents << '  twitter: '       +    ( @projectCreatorTwitter    = ''                                                ) + "\n"
        @contents << 'version: '         +    ( @projectVersion           = @projectMavenVersion                              ) + "\n"
        @contents << 'license: '         +    ( @projectLicense           = addGithubLicense                                  ) + "\n"
        @contents << 'image: '           +    ( @projectImage             = '/assets/img/libraries/' + @projectName + '.jpg'  ) + "\n"
        @contents << 'youtubeId: '       +    ( @projectYoutubeId         = ''                                                ) + "\n"
        @contents << '---'                                                                                                      + "\n"

        addGithubReadMe
        @dirname = File.basename(url, ".json")
        createFolder(@dirname)
        setFileName
        if saveFile
          shareImgGenerate(@projectName, @projectDescription)
          success
        end
      rescue => @e
        puts "\033[31m" + @e.inspect + "\033[0m\n"
        puts HR
      end
    end
  end
end

newsite = Crawl.new
newsite.parseJSON()
