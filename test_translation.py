"""
한글-영어 번역 기능 테스트
"""

import requests

def test_translation():
    """번역 API 테스트"""
    
    test_cases = [
        "아름다운 일몰의 풍경",
        "미래 도시의 네온 불빛",
        "우주 비행사가 달을 탐험하는 모습",
        "판타지 숲속의 마법사",
        "비 오는 거리의 사이버펑크 풍경",
        "벚꽃이 흩날리는 봄날",
        "고양이와 강아지가 함께 노는 모습",
        "Beautiful sunset over the ocean",  # 영어는 그대로
    ]
    
    print("=" * 50)
    print("번역 API 테스트")
    print("=" * 50)
    
    for text in test_cases:
        try:
            response = requests.post(
                "http://localhost:8001/api/translate",
                data={"text": text, "target_lang": "en"}
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"\n원문: {result['original']}")
                print(f"번역: {result['translated']}")
                print(f"언어: {result['language']}")
            else:
                print(f"오류: {response.status_code}")
                
        except Exception as e:
            print(f"연결 실패: {e}")
    
    print("\n" + "=" * 50)
    print("테스트 완료!")

if __name__ == "__main__":
    test_translation()