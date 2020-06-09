# "The Rails Port"

[![Build Status](https://travis-ci.org/openstreetmap/openstreetmap-website.svg?branch=master)](https://travis-ci.org/openstreetmap/openstreetmap-website)
[![Coverage Status](https://coveralls.io/repos/openstreetmap/openstreetmap-website/badge.svg?branch=master)](https://coveralls.io/r/openstreetmap/openstreetmap-website?branch=master)


Rails Port란 OpenStreetMap 웹사이트와 API를 구동하는[Ruby on Rails](http://rubyonrails.org/)애플리케이션이다. 
그 소프트웨어는 또한 “openstreetmap-website”로도 알려져 있습니다.

이 저장소는 다음과 같이 구성됩니다.

* 사용자의 계정, 다이어리 객체, 사용자 간의 메시징을 포함한 웹 사이트
* XML을 기반으로 한 [API](https://wiki.openstreetmap.org/wiki/API_v0.6) 편집
*  [Potlatch](https://wiki.openstreetmap.org/wiki/Potlatch_1)와 [Potlatch 2](https://wiki.openstreetmap.org/wiki/Potlatch_2) 그리고[iD](https://wiki.openstreetmap.org/wiki/ID) 편집기들의 통합된 버전들
* 검색 페이지 – OpenStreetMap데이터에 대한 웹의 전면
* GPX 업로드, 탐색 그리고 API

완전한 기능의 Rails Port 설치는 다른 소프트웨어에 의해 제공되는 맵 타일 서버와 geocoding 서비스를 포함한 다른 서비스들에 의존한다. 
그 default 설치는 공개적으로 이용가능한 서비스들을 사용하여 개발과 테스트에 도움을 줍니다.

# 특허

이 소프트웨어는 [GNU General Public License 2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt) 하에 라이선스가 부여되고 복제본은 [LICENSE](LICENSE) 파일에서 찾을 수 있습니다.

# 설치

Rails Port는 이것의 데이터 베이스로써 PostgreSQL을 사용하는 Ruby on Rails 애플리케이션이다.
 그리고 설치에 대한 많은 수의 의존성이 있다. 완전히 자세한 내용은 [INSTALL.md](INSTALL.md)를 보십시오.

# 개발

우리는 항상 더 많은 개발자들을 가지길 열망합니다! Pull requests를 매우 환영합니다.

* 버그는 [issue tracker](https://github.com/openstreetmap/openstreetmap-website/issues)에 기록됩니다.
* 몇몇 버그 보고서는 또한  [OpenStreetMap trac](https://trac.openstreetmap.org/)  시스템의 "[website](https://trac.openstreetmap.org/query?status=new&status=assigned&status=reopened&component=website&order=priority)" 와"[api](https://trac.openstreetmap.org/query?status=new&status=assigned&status=reopened&component=api&order=priority)" 에서 찾을 수 있습니다.
* 번역은 [Translatewiki](https://translatewiki.net/wiki/Translating:OpenStreetMap)에 의해 관리됩니다.
* 개발 논의를 위한 메일링 리스트인 [rails-dev@openstreetmap.org](https://lists.openstreetmap.org/listinfo/rails-dev) 도 있습니다.
* IRC – irc.oftc.net에 #osm-dev 채널이 있습니다.

코드 분배에 대한 더 많은 세부사항은 [CONTRIBUTING.md](CONTRIBUTING.md) 파일에 있습니다.

# 관리자

* Tom Hughes [@tomhughes](https://github.com/tomhughes/)
* Andy Allan [@gravitystorm](https://github.com/gravitystorm/)
