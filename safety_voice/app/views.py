from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .serializers import UserSerializer

User = get_user_model()

@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    try:
        data = request.data
        
        # 필수 필드 검증
        required_fields = ['nickname', 'username', 'password', 'location', 'email']
        for field in required_fields:
            if not data.get(field):
                return Response(
                    {'error': f'{field}는 필수 항목입니다.'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # 이메일 중복 검사
        if User.objects.filter(email=data['email']).exists():
            return Response(
                {'error': '이미 등록된 이메일입니다.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # 아이디 중복 검사
        if User.objects.filter(username=data['username']).exists():
            return Response(
                {'error': '이미 사용중인 아이디입니다.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # 사용자 생성
        user = User.objects.create_user(
            username=data['username'],
            email=data['email'],
            password=data['password']
        )
        
        # 추가 정보 저장
        user.nickname = data['nickname']
        user.location = data['location']
        user.save()

        # 사용자 정보 반환
        serializer = UserSerializer(user)
        return Response(
            {'message': '회원가입이 완료되었습니다.', 'user': serializer.data},
            status=status.HTTP_201_CREATED
        )

    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
from django.contrib.auth import authenticate
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model

User = get_user_model()

@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    data = request.data
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return Response(
            {'error': '아이디와 비밀번호를 입력하세요.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    user = authenticate(username=username, password=password)
    
    if user is not None:
        # 토큰 발급 (DRF TokenAuthentication 사용 시)
        token, _ = Token.objects.get_or_create(user=user)
        return Response(
            {'message': '로그인 성공', 'token': token.key},
            status=status.HTTP_200_OK
        )
    else:
        return Response(
            {'error': '아이디 또는 비밀번호가 올바르지 않습니다.'},
            status=status.HTTP_401_UNAUTHORIZED
        )

import whisper
import os
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.files.storage import default_storage

@csrf_exempt
def transcribe_audio(request):
    if request.method == 'POST' and request.FILES.get('audio'):
        audio_file = request.FILES['audio']
        file_path = default_storage.save('uploads/' + audio_file.name, audio_file)

        # Whisper 모델 로드
        model = whisper.load_model("base")

        # 오디오 파일 변환 및 STT 수행
        result = model.transcribe(file_path)
        text = result["text"]

        # 파일 삭제
        os.remove(file_path)

        return JsonResponse({'text': text}, status=200)
    
    return JsonResponse({'error': 'Invalid request'}, status=400)