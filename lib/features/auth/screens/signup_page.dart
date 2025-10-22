import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _phoneController = TextEditingController();

  // 핸드폰 번호 포맷터
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '###-####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // AuthService 인스턴스
  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;
  bool _isLoading = false;

  // 약관 동의 상태
  bool _agreeAll = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 전체 동의 처리
  void _handleAgreeAll(bool? value) {
    setState(() {
      _agreeAll = value ?? false;
      _agreeTerms = _agreeAll;
      _agreePrivacy = _agreeAll;
      _agreeMarketing = _agreeAll;
    });
  }

  // 개별 동의 처리
  void _handleIndividualAgree() {
    setState(() {
      _agreeAll = _agreeTerms && _agreePrivacy && _agreeMarketing;
    });
  }

  // 회원가입 처리
  Future<void> _handleSignup() async {
    // 필수 약관 체크
    if (!_agreeTerms || !_agreePrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 약관에 동의해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Firebase 회원가입 호출
        final user = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (mounted && user != null) {
          // 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원가입 성공! 로그인 해주세요.'),
              backgroundColor: Colors.green,
            ),
          );

          // 로그인 페이지로 이동
          Navigator.pop(context);
        }
      } catch (e) {
        setState(() => _isLoading = false);

        if (mounted) {
          // 에러 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 약관 상세보기
  void _showTermsDetail(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이메일
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 비밀번호
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '영문, 숫자 포함 8자 이상',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 8) {
                      return '비밀번호는 8자 이상이어야 합니다';
                    }
                    if (!RegExp(r'[a-zA-Z]').hasMatch(value) ||
                        !RegExp(r'[0-9]').hasMatch(value)) {
                      return '영문과 숫자를 포함해야 합니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 비밀번호 확인
                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: !_isPasswordConfirmVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    hintText: '비밀번호를 다시 입력하세요',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordConfirmVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordConfirmVisible = !_isPasswordConfirmVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 핸드폰 번호
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneMaskFormatter],
                  decoration: const InputDecoration(
                    labelText: '핸드폰 번호',
                    hintText: '010-1234-5678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '핸드폰 번호를 입력해주세요';
                    }
                    // 숫자만 추출
                    final numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (numbers.length != 11) {
                      return '올바른 핸드폰 번호가 아닙니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // 약관 동의 구분선
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 전체 동의
                CheckboxListTile(
                  value: _agreeAll,
                  onChanged: _handleAgreeAll,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '전체 동의',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Divider(height: 1),
                const SizedBox(height: 8),

                // 이용약관 동의 (필수)
                CheckboxListTile(
                  value: _agreeTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeTerms = value ?? false;
                      _handleIndividualAgree();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: '이용약관 동의 '),
                              TextSpan(
                                text: '(필수)',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showTermsDetail(
                          '이용약관',
                          '여기에 실제 이용약관 내용이 들어갑니다.\n\n제1조 (목적)\n본 약관은...',
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('보기'),
                      ),
                    ],
                  ),
                ),

                // 개인정보 처리방침 동의 (필수)
                CheckboxListTile(
                  value: _agreePrivacy,
                  onChanged: (value) {
                    setState(() {
                      _agreePrivacy = value ?? false;
                      _handleIndividualAgree();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: '개인정보 처리방침 동의 '),
                              TextSpan(
                                text: '(필수)',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showTermsDetail(
                          '개인정보 처리방침',
                          '여기에 실제 개인정보 처리방침 내용이 들어갑니다.\n\n1. 수집하는 개인정보...',
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('보기'),
                      ),
                    ],
                  ),
                ),

                // 마케팅 정보 수신 동의 (선택)
                CheckboxListTile(
                  value: _agreeMarketing,
                  onChanged: (value) {
                    setState(() {
                      _agreeMarketing = value ?? false;
                      _handleIndividualAgree();
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: '마케팅 정보 수신 동의 '),
                              TextSpan(
                                text: '(선택)',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showTermsDetail(
                          '마케팅 정보 수신 동의',
                          '여기에 마케팅 정보 수신 동의 내용이 들어갑니다.\n\n이벤트, 프로모션...',
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('보기'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 회원가입 버튼
                FilledButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 로그인 페이지로
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '이미 계정이 있으신가요? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '로그인',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}