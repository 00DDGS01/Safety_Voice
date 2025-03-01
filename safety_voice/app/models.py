from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser) :
    nickname = models.CharField(max_length=50)
    location = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'users'

# Recording
class Recording(models.Model) :
    user = models.ForeignKey(settings.AUTH_USER_MODEL, 
                             on_delete=models.CASCADE,      # CASCADE
                             primary_key=True)
    recording_name = models.CharField(max_length=255)       # 녹음 파일 이름    
    recording_duration = models.IntegerField()              # 초 단위 저장
    file_size = models.BigIntegerField()                    # 파일 사이즈 (바이트 단위)
    file_path = models.TextField()                          # 파일 저장 경로 -> 이건 생각을 더 해봐야할듯 (물어봐야 함)
    created_at = models.DateTimeField(auto_now_add=True)    # 녹음 생성 시간

    class Meta:
        db_table = "recordings"

    # 객체 -> 문자열
    '''
    def __str__(self):
        return f"{self.recording_name} ({self.user.username})"
    '''

# SafeZone
class SafeZone(models.Model) :
    start_time = models.TimeField()  # 시작 시간
    end_time = models.TimeField()  # 종료 시간
    days_active = models.CharField(max_length=20, default="월,화,수,목,금")  # 활성 요일

    class Meta:
        db_table = "safe_zones"
        ordering = ["-created_at"]  # 최신 데이터가 먼저 나오도록 정렬

    def __str__(self):
        return f"{self.name} ({self.user.username})"