# 무협 UI 서체

외부 설치 없이 동작하도록 SIL Open Font License 1.1 서체를 프로젝트에 포함한다.

| 용도 | 서체 | 원본·라이선스 |
| --- | --- | --- |
| 제목·인물 이름 | Nanum Brush Script (나눔손글씨 붓) | [Google Fonts 원본](https://github.com/google/fonts/tree/main/ofl/nanumbrushscript), `NanumBrushScript-OFL.txt` |
| 대사·설명·수치 | Nanum Myeongjo (나눔명조) | [Google Fonts 원본](https://github.com/google/fonts/tree/main/ofl/nanummyeongjo), `NanumMyeongjo-OFL.txt` |
| 현재 사용하는 한자 네 글자 `序章長沙` | Murim Hanja Fallback | Noto Serif CJK KR 파생 부분집합, `NotoSerifCJK-OFL.txt` |

두 나눔 TTF는 원본 그대로이며 각각 한글 11,172자를 지원한다. `ink_body.tres`와 `ink_brush.tres`가 게임에서 사용하는 FontVariation 자원이다. 작은 글씨·긴 대사·수치는 명조체로 가독성을 확보한다.

한자 보조 서체는 [Noto Serif CJK](https://github.com/notofonts/noto-cjk)의 한국어 Regular 서체에서 fontTools.subset으로 현재 필요한 네 글자만 추출했다. 원 저작권 표기는 보존하고, 파생 서체의 family/full/PostScript/CFF 이름을 `Murim Hanja Fallback` / `MurimHanjaFallback-Regular`로 변경했다. 게임에 새로운 한자를 추가하면 보조 서체의 글리프 지원도 함께 점검한다.

원본 서체와 파생 서체 모두 각 OFL 문서를 함께 배포한다. 실행 시 원격 서체를 요청하지 않는다.
