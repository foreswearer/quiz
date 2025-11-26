// dashboard.js - Teacher Dashboard

let teacherDNI = null;
let chartsInstances = {}; // Store chart instances for cleanup

// =======================
// Utility functions
// =======================

function getCookie(name) {
    const value = `; ${document.cookie}`;
    const parts = value.split(`; ${name}=`);
    if (parts.length === 2) return parts.pop().split(';').shift();
    return null;
}

function deleteCookie(name) {
    document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
}

function showError(message) {
    const errorDiv = document.getElementById('error');
    errorDiv.textContent = message;
    errorDiv.classList.remove('hidden');
}

function hideError() {
    const errorDiv = document.getElementById('error');
    errorDiv.classList.add('hidden');
}

// =======================
// Theme toggle
// =======================

function initTheme() {
    const savedTheme = localStorage.getItem('quiz_theme') || 'light';
    if (savedTheme === 'dark') {
        document.body.classList.add('dark');
        document.getElementById('theme-toggle').textContent = '☀️';
    } else {
        document.getElementById('theme-toggle').textContent = '🌙';
    }

    document.getElementById('theme-toggle').addEventListener('click', () => {
        document.body.classList.toggle('dark');
        const isDark = document.body.classList.contains('dark');
        document.getElementById('theme-toggle').textContent = isDark ? '☀️' : '🌙';
        localStorage.setItem('quiz_theme', isDark ? 'dark' : 'light');
    });
}

// =======================
// End session
// =======================

function initEndSession() {
    document.getElementById('end-session-btn').addEventListener('click', () => {
        deleteCookie('quiz_dni');
        window.location.href = '/';
    });
}

// =======================
// Check teacher access
// =======================

async function checkTeacherAccess() {
    teacherDNI = getCookie('quiz_dni');
    if (!teacherDNI) {
        showError('No DNI found. Redirecting to portal...');
        setTimeout(() => window.location.href = '/', 2000);
        return false;
    }

    // We'll verify teacher status when fetching dashboard data
    return true;
}

// =======================
// Fetch dashboard data
// =======================

async function fetchDashboardData() {
    try {
        const response = await fetch(`/teacher/dashboard_overview?teacher_dni=${encodeURIComponent(teacherDNI)}`);
        const data = await response.json();

        if (data.error) {
            showError(data.error + ' - Redirecting to portal...');
            setTimeout(() => window.location.href = '/', 2000);
            return null;
        }

        return data;
    } catch (error) {
        showError('Failed to fetch dashboard data: ' + error.message);
        return null;
    }
}

// =======================
// Populate KPIs
// =======================

function populateKPIs(data) {
    const summary = data.summary;

    document.getElementById('teacher-name').textContent = `Welcome, ${summary.teacher.name}`;
    document.getElementById('kpi-students').textContent = summary.total_students;
    document.getElementById('kpi-tests').textContent = summary.total_tests;
    document.getElementById('kpi-attempts').textContent = summary.total_attempts;
    document.getElementById('kpi-recent').textContent = summary.attempts_last_7_days;

    const avgPercentage = summary.avg_percentage;
    if (avgPercentage !== null) {
        document.getElementById('kpi-avg').textContent = avgPercentage.toFixed(1) + '%';
    } else {
        document.getElementById('kpi-avg').textContent = 'N/A';
    }
}

// =======================
// Create charts
// =======================

function createAttemptsOverTimeChart(data) {
    const canvas = document.getElementById('chart-attempts-time');
    const ctx = canvas.getContext('2d');

    // Destroy existing chart if any
    if (chartsInstances.attemptsTime) {
        chartsInstances.attemptsTime.destroy();
    }

    const attemptsOverTime = data.attempts_over_time || [];

    if (attemptsOverTime.length === 0) {
        canvas.parentElement.innerHTML = '<p class="no-data">No data available</p>';
        return;
    }

    const labels = attemptsOverTime.map(d => d.day);
    const attemptsCounts = attemptsOverTime.map(d => d.attempts);
    const avgPercentages = attemptsOverTime.map(d => d.avg_percentage || 0);

    chartsInstances.attemptsTime = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Attempts',
                    data: attemptsCounts,
                    borderColor: 'rgb(59, 130, 246)',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    yAxisID: 'y',
                    tension: 0.2
                },
                {
                    label: 'Avg Score %',
                    data: avgPercentages,
                    borderColor: 'rgb(34, 197, 94)',
                    backgroundColor: 'rgba(34, 197, 94, 0.1)',
                    yAxisID: 'y1',
                    tension: 0.2
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            aspectRatio: 2,
            interaction: {
                mode: 'index',
                intersect: false,
            },
            plugins: {
                legend: {
                    position: 'top',
                }
            },
            scales: {
                y: {
                    type: 'linear',
                    display: true,
                    position: 'left',
                    title: {
                        display: true,
                        text: 'Attempts'
                    }
                },
                y1: {
                    type: 'linear',
                    display: true,
                    position: 'right',
                    title: {
                        display: true,
                        text: 'Average %'
                    },
                    grid: {
                        drawOnChartArea: false,
                    },
                    min: 0,
                    max: 100
                }
            }
        }
    });
}

function createTestScoresChart(data) {
    const canvas = document.getElementById('chart-test-scores');
    const ctx = canvas.getContext('2d');

    // Destroy existing chart if any
    if (chartsInstances.testScores) {
        chartsInstances.testScores.destroy();
    }

    const tests = data.tests || [];

    if (tests.length === 0) {
        canvas.parentElement.innerHTML = '<p class="no-data">No data available</p>';
        return;
    }

    // Only show tests with attempts
    const testsWithAttempts = tests.filter(t => t.attempts > 0);

    if (testsWithAttempts.length === 0) {
        canvas.parentElement.innerHTML = '<p class="no-data">No tests with attempts yet</p>';
        return;
    }

    const labels = testsWithAttempts.map(t => t.title.length > 20 ? t.title.substring(0, 20) + '...' : t.title);
    const avgScores = testsWithAttempts.map(t => t.avg_percentage || 0);

    chartsInstances.testScores = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Average Score %',
                data: avgScores,
                backgroundColor: 'rgba(59, 130, 246, 0.7)',
                borderColor: 'rgb(59, 130, 246)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            aspectRatio: 2,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100,
                    title: {
                        display: true,
                        text: 'Average %'
                    }
                }
            }
        }
    });
}

// =======================
// Populate tables
// =======================

function populateHardestQuestionsTable(data) {
    const tbody = document.querySelector('#hardest-questions-table tbody');
    const questions = data.hardest_questions || [];

    if (questions.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="no-data">No data available</td></tr>';
        return;
    }

    tbody.innerHTML = '';
    questions.forEach(q => {
        const row = document.createElement('tr');

        // Truncate long questions
        const questionText = q.text.length > 60 ? q.text.substring(0, 60) + '...' : q.text;
        const wrongRate = q.wrong_rate !== null ? (q.wrong_rate * 100).toFixed(1) + '%' : 'N/A';

        row.innerHTML = `
            <td title="${q.text}">${questionText}</td>
            <td>${q.correct_count}</td>
            <td>${q.wrong_count}</td>
            <td><strong>${wrongRate}</strong></td>
        `;
        tbody.appendChild(row);
    });
}

function populateTestSummaryTable(data) {
    const tbody = document.querySelector('#test-summary-table tbody');
    const tests = data.tests || [];

    if (tests.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="no-data">No tests available</td></tr>';
        return;
    }

    tbody.innerHTML = '';
    tests.forEach(t => {
        const row = document.createElement('tr');

        const testTitle = t.title.length > 30 ? t.title.substring(0, 30) + '...' : t.title;
        const avgPct = t.avg_percentage !== null ? t.avg_percentage.toFixed(1) + '%' : 'N/A';
        const minPct = t.min_percentage !== null ? t.min_percentage.toFixed(1) + '%' : 'N/A';
        const maxPct = t.max_percentage !== null ? t.max_percentage.toFixed(1) + '%' : 'N/A';

        row.innerHTML = `
            <td title="${t.title}">${testTitle}</td>
            <td>${t.attempts}</td>
            <td>${avgPct}</td>
            <td>${minPct}</td>
            <td>${maxPct}</td>
        `;
        tbody.appendChild(row);
    });
}

// =======================
// Initialize dashboard
// =======================

async function initDashboard() {
    // Check access
    const hasAccess = await checkTeacherAccess();
    if (!hasAccess) return;

    // Fetch data
    const data = await fetchDashboardData();
    if (!data) return;

    // Populate everything
    populateKPIs(data);
    createAttemptsOverTimeChart(data);
    createTestScoresChart(data);
    populateHardestQuestionsTable(data);
    populateTestSummaryTable(data);

    hideError();
}

// =======================
// On page load
// =======================

document.addEventListener('DOMContentLoaded', () => {
    initTheme();
    initEndSession();
    initDashboard();
});